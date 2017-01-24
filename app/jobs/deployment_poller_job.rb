# Job to handle kicking off a Deployment request
class DeploymentPollerJob < ApplicationJob
  queue_as :default

  def perform(args = {})
    DeploymentPoller.run(args)
  rescue StandardError => e
    Raven.capture_exception(e)
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args_list.inspect}"
  end
end
