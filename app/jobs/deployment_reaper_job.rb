# Job to handle kicking off a Deployment request
class DeploymentReaperJob < ApplicationJob
  queue_as :default

  def build_url(app_name, build_id)
    "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{build_id}"
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def perform(*args_list)
    args = args_list.first

    sha            = args.fetch(:sha)
    repo           = args.fetch(:repo)
    name           = args.fetch(:name)
    app_name       = args.fetch(:app_name)
    build_id       = args.fetch(:build_id)
    command_id     = args.fetch(:command_id)
    deployment_url = args.fetch(:deployment_url)

    command  = Command.find(command_id)
    pipeline = command.handler.pipelines[name]

    info = pipeline.reap_build(app_name, build_id)
    if info
      artifact = { sha: sha, slug: info["slug"]["id"], repo: repo }
      Rails.logger.info "Build Complete: #{artifact.to_json}"

      payload = {
        state: "failure",
        target_url:  build_url(app_name, build_id),
        description: "Chat deployment complete. slash-heroku"
      }
      payload[:state] = "success" if info["status"] == "succeeded"

      pipeline.create_deployment_status(deployment_url, payload)
    elsif command.created_at > 15.minutes.ago
      DeploymentReaperJob.set(wait: 10.seconds).perform_later(args)
    else
      Rails.logger.info "Build expired for command: #{command.id}"
      payload = {
        state: "failure",
        target_url:  build_url(app_name, build_id),
        description: "Heroku build took longer than 15 minutes."
      }
      pipeline.create_deployment_status(deployment_url, payload)
    end
  rescue StandardError => e
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args_list.inspect}"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
