require "aws-sdk-rds"

# Rails 7.1 calls new_client for both initial connections and reconnects.
# Generate tokens here rather than in database.yml, which is evaluated at boot.
module RdsIamAuthentication
  module Reconnect
    private

    def reconnect
      return super unless ENV["PG_AUTH_MODE"] == "iam"

      # Rails normally calls PG#reset, which reuses the original login token.
      # Open a new client instead so reconnects after 15 minutes are signed again.
      begin
        @raw_connection&.close
      rescue PG::Error
        # A broken socket must not prevent opening a replacement connection.
      end
      @raw_connection = nil
      connect
    end
  end

  def new_client(conn_params)
    return super unless ENV["PG_AUTH_MODE"] == "iam"

    region = ENV.fetch("AWS_REGION")
    raise ArgumentError, "AWS_REGION must not be empty for IAM authentication" if region.empty?

    credentials = Aws::CredentialProviderChain.new.resolve
    unless credentials
      raise "No AWS credentials available for RDS IAM authentication; check the EC2 role and container IMDS access"
    end

    token = Aws::RDS::AuthTokenGenerator.new(credentials: credentials).auth_token(
      region: region,
      endpoint: "#{conn_params.fetch(:host)}:#{conn_params.fetch(:port, 5432)}",
      user_name: conn_params.fetch(:user)
    )

    # Never mutate the adapter's saved parameters or retain an expired token.
    super(conn_params.merge(
      password: token,
      sslmode: "verify-full",
      sslrootcert: ENV.fetch("PGSSLROOTCERT", "/rails/config/certs/rds-global-bundle.pem")
    ))
  end
end
