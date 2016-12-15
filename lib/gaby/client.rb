require 'google/api_client'
require 'google/api_client/auth/file_storage'
require 'singleton'
require 'json'
require 'active_support/all'
require 'pathname'

module Gaby
  class Configuration
    include Singleton
    attr_accessor :view_id, :key_file, :secret, :account, :client_id, :cached_file_path
  end

  module Client
    class << self
      END_POINT   = 'https://analyticsreporting.googleapis.com/v4/reports:batchGet'
      VERSION     = 'v4'
      APP_NAME    = "Gaby"
      APP_VERSION = "0.1.0"
      CACHED_FILE = "analytics-#{VERSION}.cache"

      def config
        Gaby::Configuration.instance
      end

      def configure
        yield config
      end

      def client
        @client ||= Google::APIClient.new(
          application_name:    APP_NAME,
          application_version: APP_VERSION,
        )
      end

      def oauth_type
        if config.key_file # && config.secret && config.account
          :p12
        elsif config.client_id # && config.secret
          :browser
        end
      end

      def authorize!
        cached_file = Pathname.new(config.cached_file_path.to_s).join(CACHED_FILE)
        authfile = Google::APIClient::FileStorage.new(cached_file)

        if authfile.authorization.nil?
          client.authorization = Signet::OAuth2::Client.new(
            token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
            audience:             'https://accounts.google.com/o/oauth2/token',
            scope:                'https://www.googleapis.com/auth/analytics.readonly',
          )
          case oauth_type
          when :p12
            # p12キーでの認証はリフレッシュトークンもらえない
            client.authorization.issuer = config.account
            client.authorization.signing_key = signing_key
          when :browser
            code = open_authorize_view(config.client_id, 'https://www.googleapis.com/auth/analytics.readonly')
            client.authorization.tap do |auth|
              auth.client_id     = config.client_id
              auth.client_secret = config.secret
              auth.redirect_uri  = 'urn:ietf:wg:oauth:2.0:oob'
              auth.code          = code
            end
          end
          client.authorization.fetch_access_token!
          authfile.write_credentials(client.authorization.dup)
        else
          client.authorization = authfile.authorization
        end
        @authorized = true
      rescue
        @authorized = false
      end

      def refresh!
        client.authorization.refresh!
        @authorized = true
      rescue
        @authorized = false
      end

      def authorized?
        @authorized
      end

      def get(query)
        # 単一レポートのリクエスト
        return unless query.is_a?(Gaby::Query)
        response = excute(query)
        # TODO: エラー処理
        # 100秒あたりのリクエスト制限に達した場合はウェイトしてリトライする
        if response["error"].present?
          response
        else
          Gaby::ReportData.new(response["reports"].first, query)
        end
      end

      def gets(*queries)
        # 複数レポートの一括リクエスト
        response = excute(*queries)
        Gaby::ReportData.new(response, query)
      end

      def get_raw(query)
        return unless query.is_a?(Gaby::Query)
        excute(query)
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
        client.authorization.access_token
      end

      def refresh_token
        client.authorization.refresh_token
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

      def parse_query(*query)
        request_query = {reportRequests: []}
        query.each do |q|
          request_query[:reportRequests] << q.to_query
        end
        request_query
      end

      def browser_open(uri)
        uri = URI.parse(uri.to_s)
        unless %w[ http https ftp file ].include?(uri.scheme)
          raise ArgumentError
        end
        case RUBY_PLATFORM
        when /mswin(?!ce)|mingw|bccwin/
          system %!start /B #{uri}!
        when /cygwin/
          system %!cmd /C start /B #{uri}!
        when /darwin/
          system %!open '#{uri}'!
        when /linux/
          system %!xdg-open '#{uri}'!
        when /java/
          require 'java'
          import 'java.awt.Desktop'
          import 'java.net.URI'
          Desktop.getDesktop.browse java.net.URI.new(uri)
        else
          raise NotImplementedError
        end
      end

      def open_authorize_view(client_id, scope, redirect_uri = 'urn:ietf:wg:oauth:2.0:oob')
        puts "open url"
        url = "https://accounts.google.com/o/oauth2/auth?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=#{scope}&response_type=code&approval_prompt=force&access_type=offline"
        puts url
        browser_open(url)
        print "\nenter code: "
        code = STDIN.gets.chomp
        return code
      end
    end
  end
end
