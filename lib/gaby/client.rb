require 'google/api_client'
require 'singleton'
require 'json'
require 'active_support/all'

module Gaby
  class Configuration
    include Singleton
    attr_accessor :view_id, :key_file, :secret, :account
  end

  module Client
    class << self
      END_POINT       = 'https://analyticsreporting.googleapis.com/v4/reports:batchGet'
      VERSION         = 'v4'
      APP_NAME        = "Gaby"
      APP_VERSION     = "0.1.0"
      CACHED_API_FILE = "./tmp/cache/google_api/analytics-#{VERSION}.cache"

      attr_reader :client

      def config
        Gaby::Configuration.instance
      end

      def configure
        yield config
      end

      def authorize!
        return authorized if authorized?

        @client = Google::APIClient.new(
          application_name:    APP_NAME,
          application_version: APP_VERSION,
        )
        @client.authorization = Signet::OAuth2::Client.new(
          token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
          audience:             'https://accounts.google.com/o/oauth2/token',
          scope:                'https://www.googleapis.com/auth/analytics.readonly',
          issuer:               config.account,
          signing_key:          signing_key,
        )
        @client.authorization.fetch_access_token!
        @authorized = true
      rescue
        @authorized = false
      end

      def authorized?
        @authorized
      end

      def excute(*query)
        uri = URI.parse(END_POINT)
        request = Net::HTTP::Post.new(uri.path, {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{access_token}",
        })

        request.body = parse_query(*query).to_json

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.start { |h| h.request(request) }
        JSON.parse(response.body)
      end

      def excute_all(query)
      end

      private

      def signing_key
        return if @signing_key
        @signing_key = Google::APIClient::KeyUtils.load_from_pkcs12(
          config.key_file,
          config.secret,
        )
      end

      def access_token
        @client.authorization.access_token
      end

      def parse_query(*query)
        request_query = {reportRequests: []}
        query.each do |q|
          request_query[:reportRequests] << q.to_query
        end
        request_query
      end
    end
  end
end
