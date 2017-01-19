# Session controller for authenticating users with GitHub/Heroku/Hipchat
class SessionsController < ApplicationController
  include SessionsHelper

  def create_github
    user = User.find(session[:user_id])
    user.github_login = omniauth_info["info"]["nickname"]
    user.github_token = omniauth_info["credentials"]["token"]

    Librato.increment "auth.create.github"

    user.save
    redirect_to after_successful_heroku_user_setup_path
  rescue ActiveRecord::RecordNotFound
    redirect_to "/auth/slack?origin=#{omniauth_origin}"
  end

  # rubocop:disable Metrics/AbcSize
  def create_heroku
    user = User.find(session[:user_id])
    user.heroku_uuid  = omniauth_info["uid"]
    user.heroku_email = omniauth_info["info"]["email"]
    user.heroku_token = omniauth_info["credentials"]["token"]
    user.heroku_refresh_token = omniauth_refresh_token
    user.heroku_expires_at    = omniauth_expiration

    Librato.increment "auth.create.heroku"

    user.save
    redirect_to after_successful_heroku_user_setup_path
  rescue ActiveRecord::RecordNotFound
    redirect_to "/auth/slack?origin=#{omniauth_origin}"
  end
  # rubocop:enable Metrics/AbcSize

  def install_slack
    user = User.find_or_initialize_by(slack_user_id: omniauth_info_user_id)
    user.slack_user_name   = omniauth_info["info"]["user"]
    user.slack_team_id     = omniauth_info["info"]["team_id"]

    Librato.increment "auth.create.slack"

    user.save
    session[:user_id] = user.id
    redirect_to after_successful_slack_user_setup_path
  end

  def create_slack
    user = User.from_omniauth(omniauth_info)

    session[:user_id] = user.id
    redirect_to after_successful_slack_user_setup_path
  end

  def complete
    @after_success_url = "https://slack.com/messages"
    if params[:origin]
      decoded = decoded_params_origin

      @after_success_url = decoded[:uri] if decoded[:uri] =~ /^slack:/

      command = Command.find(decoded[:token])
      if command
        SignupCompleteJob.perform_later(user_id: session[:user_id],
                                        command_id: command.id)
      end
    end
  rescue StandardError, ActiveRecord::RecordNotFound
    nil
  end

  def destroy
    session.clear
    redirect_to root_url, notice: "Signed out!"
  end

  private

  def after_successful_heroku_user_setup_path
    "/auth/complete?origin=#{omniauth_origin}"
  end

  def after_successful_slack_user_setup_path
    if decoded_omniauth_origin_provider
      "/auth/#{decoded_omniauth_origin_provider}?origin=#{omniauth_origin}"
    else
      "/auth/heroku?origin=#{omniauth_origin}"
    end
  end
end
