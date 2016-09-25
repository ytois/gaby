module Gaby
  class << self
    VERSION         = 'v3'
    APP_NAME        = "Gaby"
    APP_VERSION     = "0.1.0"
    ACCOUNT         = ''
    KEY_FILE        = "google.p12"
    SECRET          = ''
    CACHED_API_FILE = "./tmp/cache/google_api/analytics-#{VERSION}.cache"
    DEFAULT_VIEW_ID = ""

    attr_accessor :view_id
    attr_reader :client

    @view_id = DEFAULT_VIEW_ID

    def settings
    end

    def signing_key
      return if @signing_key
      @signing_key = Google::APIClient::KeyUtils.load_from_pkcs12(KEY_FILE, SECRET)
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
        issuer:               ACCOUNT, 
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
  end
end
