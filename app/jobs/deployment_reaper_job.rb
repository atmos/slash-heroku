# Job to handle kicking off a Deployment request
class DeploymentReaperJob < ApplicationJob
  queue_as :default

  def build_url(app_name, build_id)
    "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{build_id}"
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def perform(*args_list)
    args = args_list.first

    sha            = args.fetch(:sha)
    repo           = args.fetch(:repo)
    app_name       = args.fetch(:app_name)
    build_id       = args.fetch(:build_id)
    command_id     = args.fetch(:command_id)
    deployment_url = args.fetch(:deployment_url)

    command  = Command.find(command_id)
    pipeline = command.handler.pipeline

    build = pipeline.reap_build(app_name, build_id)
    if build
      artifact = { sha: sha, slug: build.info["slug"]["id"], repo: repo }

      if build.releasing?
        Rails.logger.info "Build Complete: #{artifact.to_json}. Releasing..."
        payload = {
          state: "pending",
          target_url:  build_url(app_name, build_id),
          description: "Build phase completed. Running release phase."
        }
        pipeline.create_deployment_status(deployment_url, payload)
        ReleaseReaperJob.perform_later(
          args.merge(release_id: build.release_id)
        )
      else
        Rails.logger.info "Build Complete: #{artifact.to_json}."
        payload = {
          state: "failure",
          target_url:  build_url(app_name, build_id),
          description: "Build phase completed. slash-heroku"
        }
        payload[:state] = "success" if build.status == "succeeded"

        pipeline.create_deployment_status(deployment_url, payload)
      end
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
    Raven.capture_exception(e)
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args_list.inspect}"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
end
