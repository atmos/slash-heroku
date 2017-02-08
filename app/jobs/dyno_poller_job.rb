# Job to handle monitoring a heroku restart post-release
class DynoPollerJob < ApplicationJob
  queue_as :default

  def perform(args = {})
    DynoPoller.run(args)
  rescue StandardError => e
    Raven.capture_exception(e)
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args.inspect}"
  end
end
