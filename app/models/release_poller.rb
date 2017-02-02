# Heroku build release phase poller
class ReleasePoller
  attr_reader :args, :app_name, :app_id, :build_id,
    :release_id, :deployment_url,
    :user_id, :pipeline_name

  def self.run(args)
    poller = new(args)
    poller.run
    poller
  end

  def initialize(args = {})
    @args           = args
    @app_name       = args.fetch(:app_name)
    @app_id         = args.fetch(:app_id)
    @build_id       = args.fetch(:build_id)
    @release_id     = args.fetch(:release_id)
    @deployment_url = args.fetch(:deployment_url)
    @user_id        = args.fetch(:user_id)
    @pipeline_name  = args.fetch(:pipeline_name)
  end

  def run
    return unless release
    if release.status == "pending"
      ReleasePollerJob.set(wait: 10.seconds).perform_later(args)
    else
      release_completed
      unlock
    end
  end

  def release
    @release ||= Escobar::Heroku::Release.new(escobar_client, app_id,
                                              build_id, release_id)
  end

  private

  def unlock
    Lock.new(release.app.cache_key).unlock
  end

  def release_completed
    payload = {
      state: "failure",
      target_url:  build_url(app_name, build_id),
      description: "Release phase completed."
    }
    payload[:state] = "success" if release.status == "succeeded"

    pipeline.create_deployment_status(deployment_url, payload)
  end

  def user
    @user ||= User.find(user_id)
  end

  def escobar_client
    user.pipelines
  end

  def pipeline
    @pipeline ||= user.pipeline_for(pipeline_name)
  end

  def build_url(app_name, build_id)
    "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{build_id}"
  end
end
