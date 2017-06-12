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

      # if the user typed a `/h command` before logging in, run it now
      command = Command.find(decoded[:token])
      execute_command(command) if command
    end
  rescue StandardError, ActiveRecord::RecordNotFound
    nil
  end

  def destroy
    session.clear
    redirect_to root_url, notice: "Signed out!"
  end

  private

  def execute_command(command)
    unless command.user_id
      command.user_id = session[:user_id]
      command.save
    end

    show_login_state(command) if show_login_state?(command)
    CommandExecutorJob.perform_later(command_id: command.id)
  end

  # if the user is authenticated and we're about to run the `/h command`
  # he typed before authenticating, show him his login state as a confirmation.
  def show_login_state?(command)
    command.task != "login" && command.user.onboarded?
  end

  # we want to display a login state before running a command, we use
  # the command parameters (channel_id, response_url, ...) to run a
  # login command that will just display the login state (we don't
  # save that command)
  def show_login_state(command)
    c = command.dup
    c.task = "login"
    ExecuteCommand.for(c)
  end

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
