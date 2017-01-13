privacy_policy_url = ENV["PRIVACY_POLICY_URL"] || "https://api.slack.com/developer-policy"

require "sidekiq/web"

Rails.application.routes.draw do
  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'

  get  "/auth/failure"         => "sessions#destroy"
  get  "/auth/complete"        => "sessions#complete"
  get  "/auth/github/callback" => "sessions#create_github"
  get  "/auth/heroku/callback" => "sessions#create_heroku"
  get  "/auth/slack/callback"  => "sessions#create_slack"
  get  "/auth/slack_install/callback", to: "sessions#install_slack"

  get  "/health"   => "application#health"
  get  "/support"  => "pages#support"
  get  "/privacy", to: redirect(privacy_policy_url, status: 302)
  get  "/boomtown" => "application#boomtown"

  post "/commands" => "commands#create"
  post "/message_actions"  => "message_actions#create"
  post "/signout"  => "sessions#destroy"

  mount Sidekiq::Web => "/sidekiq", constraints: AdminConstraint.new

  root to: "pages#install"
end
