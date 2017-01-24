module Helpers
  module Api
    def default_heroku_headers(token, version = 3)
      {
        "Accept" => "application/vnd.heroku+json; version=#{version}",
        "Accept-Encoding" => "",
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "User-Agent" => "Faraday v0.9.2"
      }
    end

    def default_github_headers(token)
      {
        "Accept" => "application/vnd.github.loki-preview+json",
        "Authorization" => "token #{token}",
        "Content-Type" => "application/json",
        "User-Agent" => "Faraday v0.9.2"
      }
    end
  end
end
