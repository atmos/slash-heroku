# Endpoint for handling slack postings
class CommandsController < ApplicationController
  instrument_action :create
  protect_from_forgery with: :null_session

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def create
    if slack_token_valid?
      if current_user && current_user.heroku_token
        if current_user.github_token
          command = current_user.create_command_for(params)
          render json: command.default_response.to_json
        else
          command = Command.from_params(params)
          render json: command.authenticate_github_response
        end
      else
        command = Command.from_params(params)
        render json: command.authenticate_heroku_response
      end
    else
      render json: {}, status: 404
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity

  private

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
