unless %w[password iam].include?(ENV.fetch("PG_AUTH_MODE", "password"))
  raise ArgumentError, "PG_AUTH_MODE must be password or iam"
end

require Rails.root.join("lib/rds_iam_authentication")

ActiveSupport.on_load(:active_record) do
  require "active_record/connection_adapters/postgresql_adapter"
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.singleton_class.prepend(RdsIamAuthentication)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(RdsIamAuthentication::Reconnect)
end
