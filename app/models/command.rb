# A command a Slack User issued
class Command < ApplicationRecord
  belongs_to :user, required: false

  before_validation :extract_cli_args, on: :create

  def self.from_params(params)
    create(
      channel_id: params[:channel_id],
      channel_name: params[:channel_name],
      command: params[:command],
      command_text: params[:text],
      response_url: params[:response_url],
      slack_user_id: params[:user_id],
      team_id: params[:team_id],
      team_domain: params[:team_domain]
    )
  end

  def default_response
    { response_type: "in_channel" }
  end

  def auth_url_prefix
    "https://#{ENV['HOSTNAME']}/auth"
  end

  def slack_auth_url
    "#{auth_url_prefix}/slack?origin=#{encoded_origin_hash(:heroku)}" \
      "&team=#{team_id}"
  end

  def github_auth_url
    "#{auth_url_prefix}/github?origin=#{encoded_origin_hash(:github)}"
  end

  def authenticate_heroku_response
    {
      response_type: "in_channel",
      text: "Please <#{slack_auth_url}|sign in to Heroku>."
    }
  end

  def origin_hash(provider_name)
    {
      uri: "slack://channel?team=#{team_id}&id=#{channel_id}",
      team: team_id,
      token: id,
      provider: provider_name
    }
  end

  def encoded_origin_hash(provider_name = :heroku)
    data = JSON.dump(origin_hash(provider_name))
    Base64.encode64(data).split("\n").join("")
  end

  private

  def extract_cli_args
    self.subtask = "default"

    match = command_text.match(/^([-_\.0-9a-z]+)(?:\:([^\s]+))/)
    if match
      self.task    = match[1]
      self.subtask = match[2]
    end

    match = command_text.match(/^([-_\.0-9a-z]+)\s*/)
    self.task = match[1] if match
  end
end
