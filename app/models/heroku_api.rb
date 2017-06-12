# Small wrapper around api calls to Heroku api
class HerokuApi
  def initialize(token)
    @token = token
  end

  def user_information
    get("/account")
  end

  # Figure out how to &tail=true but just for more than 100 lines
  def logs_for(application)
    logs_at_url(get("/apps/#{application}/logs?logplex=true", 2))
  end

  def releases_for(application)
    get_range("/apps/#{application}/releases", "version; order=desc,max=10;")
  end

  def release_info_for(application, version)
    get("/apps/#{application}/releases/#{version}")
  end

  def token_refresh(refresh_token)
    client = Faraday.new(url: "https://id.heroku.com") do |c|
      c.request :url_encoded
      c.use :instrumentation
      c.use ZipkinTracer::FaradayHandler, "id.heroku.com"
      c.adapter Faraday.default_adapter
    end
    params = {
      grant_type: "refresh_token",
      refresh_token: refresh_token,
      client_secret: ENV["HEROKU_OAUTH_SECRET"]
    }
    response = client.post "/oauth/token", params

    JSON.parse(response.body)
  rescue StandardError
    response && response.body
  end

  attr_reader :token

  def heroku_accept_header(version)
    "application/vnd.heroku+json; version=#{version}"
  end

  def get(path, version = 3)
    response = client.get do |request|
      request.url path
      request.headers["Accept"] = heroku_accept_header(version)
      request.headers["Accept-Encoding"] = ""
      request.headers["Content-Type"]    = "application/json"
      request.headers["Authorization"]   = "Bearer #{token}"
    end

    JSON.parse(response.body).with_indifferent_access
  rescue StandardError
    response && response.body
  end

  def get_range(path, range, version = 3)
    response = client.get do |request|
      request.url path
      request.headers["Accept"] = heroku_accept_header(version)
      request.headers["Accept-Encoding"] = ""
      request.headers["Content-Type"]    = "application/json"
      request.headers["Authorization"]   = "Bearer #{token}"
      request.headers["Range"]           = range
    end

    JSON.parse(response.body).map(&:with_indifferent_access)
  rescue StandardError
    response && response.body
  end

  # rubocop:disable Metrics/AbcSize
  def post(path, body)
    response = client.post do |request|
      request.url path
      request.headers["Accept"] = heroku_accept_header(3)
      request.headers["Accept-Encoding"] = ""
      request.headers["Content-Type"]    = "application/json"
      if token
        request.headers["Authorization"] = "Bearer #{token}"
      end
      request.body = body.to_json
    end

    JSON.parse(response.body).with_indifferent_access
  rescue StandardError
    response && response.body
  end
  # rubocop:enable Metrics/AbcSize

  private

  def logs_at_url(url)
    uri = Addressable::URI.parse(url)
    response = logs_client.get do |request|
      request.url uri.path
      request.headers["Accept-Encoding"] = ""
      request.headers["Content-Type"]    = "application/json"
    end
    response.body
  rescue StandardError
    response && response.body
  end

  def client
    @client ||= Faraday.new(url: "https://api.heroku.com") do |c|
      c.use :instrumentation
      c.use ZipkinTracer::FaradayHandler, "api.heroku.com"
      c.adapter Faraday.default_adapter
    end
  end

  def logs_client
    @login_client ||= Faraday.new(url: "https://logs-api.heroku.com") do |c|
      c.use :instrumentation
      c.use ZipkinTracer::FaradayHandler, "logs-api.heroku.com"
      c.adapter Faraday.default_adapter
    end
  end
end
