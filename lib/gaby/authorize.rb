require 'singleton'
require 'json'

module Gaby
  class Configuration
    include Singleton
    attr_accessor :view_id, :key_file, :secret, :account
  end

  class << self
    VERSION         = 'v3'
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

    def signing_key
      return if @signing_key
      @signing_key = Google::APIClient::KeyUtils.load_from_pkcs12(
        config.key_file,
        config.secret,
      )
    end

    def authorize!
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
      @status = true
    rescue
      @status = false
    end

    def authorized?
      @status
    end

    def api
      @analytics ||= @client.discovered_api('analytics', 'v3')
    end

    def excute(query)
      raise "authorize error" unless authorized?

      res = client.execute(
        api_method: api.data.ga.get,
        parameters: query,
      )
      if res.response.status == 200
        JSON.parse(res.response.body)
      else
        # TODO: エラーハンドリング
        res
      end
    end
  end
end
