# Job to handle heroku message action execution
class MessageActionExecutorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    action_id = args.first.fetch(:action_id)
    MessageAction.find(action_id)
  end
end
