# Module for handling User's GitHub tokens.
module GitHubTokenManagement
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
  end

  def github_oauth_client_id
    ENV["GITHUB_OAUTH_ID"]
  end

  def github_oauth_client_secret
    ENV["GITHUB_OAUTH_SECRET"]
  end

  def reset_github
    revoke_github_oauth_token
  ensure
    self.github_login = nil
    self.enc_github_token = nil
  end

  # rubocop:disable Metrics/LineLength
  def github_oauth_consumer_client
    @github_oauth_consumer_client ||= begin
                                        client = Faraday.new(url: "https://api.github.com")
                                        client.basic_auth github_oauth_client_id, github_oauth_client_secret
                                        client
                                      end
  end
  # rubocop:enable Metrics/LineLength

  def reset_github_oauth_token
    client_id = github_oauth_client_id
    response = github_oauth_consumer_client.post do |req|
      req.url "/applications/#{client_id}/tokens/#{github_token}"
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["Content-Type"] = "application/json"
    end
    JSON.parse(response.body)
  end

  def revoke_github_oauth_token
    client_id = github_oauth_client_id
    response = github_oauth_consumer_client.delete do |req|
      req.url "/applications/#{client_id}/tokens/#{github_token}"
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["Content-Type"] = "application/json"
    end
    response && response.status == 204
  end

  def refresh_github_oauth_token
    response = reset_github_oauth_token
    self.github_token = response["token"]
    self.save
  end

  def github_token
    rbnacl_github_token
  end

  def rbnacl_github_token
    decrypt_value(self[:enc_github_token])
  end

  def github_token=(token)
    self[:enc_github_token] = encrypt_value(token)
  end

  def github_configured?
    !(github_token && !github_token.empty?).nil?
  end
end
