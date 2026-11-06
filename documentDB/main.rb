
require 'mongo'
require 'json'

client_host = ENV.fetch('DOCDB_URI')

client_options = {
  database: 'sample_database',
  user: ENV.fetch('DOCDB_USER'),
  password: ENV.fetch('DOCDB_PASSWORD'),

  replica_set: 'rs0',
  read: { secondary_preferred: 1 },

  ssl: true,
  ssl_verify: true,
  ssl_ca_cert: File.expand_path('global-bundle.pem', __dir__),

  retry_writes: false,
  server_selection_timeout: 10
}

client = nil

begin
  client = Mongo::Client.new(client_host, client_options)

  # Force an actual database operation to verify connectivity
  client.database.command(ping: 1)

  puts "Successfully connected to Amazon DocumentDB!"

  collection = client[:test_collection]

  collection.insert_one({
    name: 'Ruby Driver',
    type: 'Database Connection'
  })

  document = collection.find(name: 'Ruby Driver').first

  puts "Retrieved Document: #{document.to_json}"

rescue => e
  puts "Connection/Database Error: #{e.class}"
  puts e.message

ensure
  client&.close
end
