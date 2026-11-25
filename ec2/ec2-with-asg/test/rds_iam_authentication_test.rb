# No database or AWS calls: exercise the real adapter and AWS token signer,
# replacing only the final PostgreSQL connection and the clock.
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "minitest/autorun"
require "uri"

# Trigger Rails' lazy Active Record load and its initializer hook.
ActiveRecord::Base

class RdsIamAuthenticationTest < Minitest::Test
  class Connection
    attr_reader :closed

    def close
      @closed = true
    end

    def reset
      raise "IAM reconnect must not reuse the old token through PG#reset"
    end
  end

  def setup
    @environment = ENV.to_h
    ENV.update(
      "PG_AUTH_MODE" => "iam",
      "AWS_REGION" => "us-east-1",
      "AWS_ACCESS_KEY_ID" => "test-access-key",
      "AWS_SECRET_ACCESS_KEY" => "test-secret-key",
      "AWS_SESSION_TOKEN" => "test-session-token",
      "PGSSLROOTCERT" => "/test/rds-ca.pem"
    )
    @params = { host: "test.us-east-1.rds.amazonaws.com", port: 5432,
                user: "daymark_iam", dbname: "todo", password: "old-password", sslmode: "disable" }
    @connections = []
    @original_connect = PG.method(:connect)
    connections = @connections
    PG.define_singleton_method(:connect) do |**params|
      connection = Connection.new
      connections << [params, connection]
      connection
    end
  end

  def teardown
    PG.define_singleton_method(:connect, @original_connect)
    ENV.replace(@environment)
  end

  def test_reconnect_after_token_expiry_signs_a_fresh_token
    adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(
      @params.except(:user, :dbname).merge(username: @params[:user], database: @params[:dbname])
    )
    now = Time.utc(2026, 1, 1)
    original_now = Time.method(:now)
    Time.define_singleton_method(:now) { now }
    adapter.send(:connect)
    now += 16 * 60
    adapter.send(:reconnect)

    assert_equal 2, @connections.length
    first, second = @connections.map(&:first)
    refute_equal first[:password], second[:password]
    assert @connections.first.last.closed
    query = URI.decode_www_form(second[:password].split("?", 2).last).to_h
    assert_equal "daymark_iam", query["DBUser"]
    assert_equal "900", query["X-Amz-Expires"]
    assert_equal "20260101T001600Z", query["X-Amz-Date"]
    assert_equal "test-session-token", query["X-Amz-Security-Token"]
    assert_equal "verify-full", second[:sslmode]
    assert_equal "/test/rds-ca.pem", second[:sslrootcert]
    assert_equal "old-password", @params[:password]
  ensure
    Time.define_singleton_method(:now, original_now) if original_now
  end

  def test_password_mode_preserves_connection_parameters
    ENV["PG_AUTH_MODE"] = "password"
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new_client(@params)
    assert_equal @params, @connections.first.first
  end

  def test_each_endpoint_gets_its_own_iam_token
    hosts = [@params.fetch(:host), "replica.us-east-1.rds.amazonaws.com"]
    hosts.each do |host|
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new_client(@params.merge(host: host))
    end

    @connections.zip(hosts).each do |(params, _connection), host|
      assert_equal host, params.fetch(:host)
      assert params.fetch(:password).start_with?("#{host}:5432/?")
      assert_equal "verify-full", params.fetch(:sslmode)
    end
    refute_equal @connections.first.first[:password], @connections.last.first[:password]
  end

  def test_missing_region_fails_before_connecting
    ENV.delete("AWS_REGION")
    assert_raises(KeyError) do
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new_client(@params)
    end
    assert_empty @connections
  end
end
