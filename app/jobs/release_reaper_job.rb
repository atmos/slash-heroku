# Job to handle monitoring a heroku release
class ReleaseReaperJob < ApplicationJob
  queue_as :default

  def build_url(app_name, build_id)
    "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{build_id}"
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def perform(*args_list)
    args = args_list.first

    app_name       = args.fetch(:app_name)
    build_id       = args.fetch(:build_id)
    release_id     = args.fetch(:release_id)
    command_id     = args.fetch(:command_id)
    deployment_url = args.fetch(:deployment_url)

    command  = Command.find(command_id)
    pipeline = command.handler.pipeline

    release = pipeline.reap_release(app_name, build_id, release_id)
    if release
      payload = {
        state: "failure",
        target_url:  build_url(app_name, build_id),
        description: "Release phase completed."
      }
      payload[:state] = "success" if release.status == "succeeded"

      pipeline.create_deployment_status(deployment_url, payload)
    elsif command.created_at > 30.minutes.ago
      ReleaseReaperJob.set(wait: 10.seconds).perform_later(args)
    else
      Rails.logger.info "Build expired for command: #{command.id}"
      payload = {
        state: "failure",
        target_url:  build_url(app_name, build_id),
        description: "Heroku build and release took longer than 30 minutes."
      }
      pipeline.create_deployment_status(deployment_url, payload)
    end
  rescue StandardError => e
    Raven.capture_exception(e)
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args_list.inspect}"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
