# Module for handling User's Heroku tokens.
module HerokuTokenManagement
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
  end

  def reset_heroku
    self.heroku_email = nil
    self.enc_heroku_token = nil
    self.enc_heroku_refresh_token = nil
    self.heroku_expires_at = nil
  end

  def heroku_refresh_token
    decrypt_value(self[:enc_heroku_refresh_token])
  end

  def heroku_refresh_token=(token)
    self[:enc_heroku_refresh_token] = encrypt_value(token)
  end

  def heroku_configured?
    !(heroku_token && enc_heroku_token && !enc_heroku_token.empty?).nil?
  end

  def heroku_token=(token)
    self[:enc_heroku_token] = encrypt_value(token)
  end

  def rbnacl_heroku_token
    decrypt_value(self[:enc_heroku_token])
  end

  # This will refresh the token if expired.
  def heroku_token
    unless heroku_refresh_token && heroku_expires_at
      reset_heroku
      save
      return nil
    end
    if heroku_expired?
      refresh_heroku_oauth_token
    end
    rbnacl_heroku_token
  end

  def heroku_expired?
    !heroku_expires_at || heroku_expires_at < Time.now.utc
  end

  def refresh_heroku_oauth_token
    body = HerokuApi.new(nil).token_refresh(heroku_refresh_token)
    if body && body["access_token"] && body["expires_in"]
      self.heroku_token = body["access_token"]
      expires_at = Time.at(Time.now.utc.to_i + body["expires_in"]).utc
      self.heroku_expires_at = expires_at
    else
      reset_heroku
    end
    self.save
  end
end
