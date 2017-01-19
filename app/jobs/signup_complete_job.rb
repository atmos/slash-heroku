# Job to handle notifying the user that they're done signing up
class SignupCompleteJob < ApplicationJob
  queue_as :default

  def perform(*args)
    command_id = args.first.fetch(:command_id)
    user_id = args.first.fetch(:user_id)

    command = Command.find(command_id)
    unless command.user_id
      command.user_id = user_id
      command.save
    end
    command.notify_user_of_success!
    CommandExecutorJob.perform_later(command_id: command.id)
  end
end
