# Endpoint for handling slack postings
class CommandsController < ApplicationController
  instrument_action :create
  protect_from_forgery with: :null_session

  rescue_from StandardError, with: :say_oops

  def create
    if slack_token_valid?
      render json: handle_command
    else
      render json: {}, status: 404
    end
  end

  private

  def handle_command
    if current_user
      command = current_user.create_command_for(params)
      command.default_response.to_json
    else
      command = Command.from_params(params)
      HerokuCommands::Login.new(command).run
    end
  end

  def say_oops(exception)
    Raven.capture_exception(exception)
    render json: { response_type: "ephemeral",
                   text: "Oops, something went wrong." }, status: :ok
  end

  def current_user
    @current_user ||= User.find_by(slack_user_id: params[:user_id],
                                   slack_team_id: params[:team_id])
  end

  def slack_token
    ENV["SLACK_SLASH_COMMAND_TOKEN"]
  end

  def slack_token_valid?
    ActiveSupport::SecurityUtils.secure_compare(params[:token], slack_token)
  end
end
