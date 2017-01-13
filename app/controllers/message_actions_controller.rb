# Controller to process interactive messages buttons clicks
class MessageActionsController < ApplicationController
  instrument_action :create
  protect_from_forgery with: :null_session

  def create
    return render json: {}, status: 404 unless slack_token_valid?
    current_user.create_message_action_for(payload)
    render nothing: true, status: 204
  end

  private

  def current_user
    @current_user ||= User.find_by(slack_user_id: payload[:user][:id],
                                   slack_team_id: payload[:team][:id])
  end

  def slack_token
    ENV["SLACK_SLASH_COMMAND_TOKEN"]
  end

  def slack_token_valid?
    ActiveSupport::SecurityUtils.secure_compare(payload[:token], slack_token)
  end

  def payload
    @payload ||= JSON.parse(params[:payload]).with_indifferent_access
  end
end
