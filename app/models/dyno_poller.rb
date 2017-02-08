# Heroku dyno restart poller
class DynoPoller
  attr_reader :args, :app_name, :app_id, :build_id,
    :release_id, :deployment_url, :epoch,
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
    @epoch          = Time.parse(args.fetch(:epoch)).utc
    @pipeline_name  = args.fetch(:pipeline_name)
  end

  def run
    return unless app
    Rails.logger.info at: "dyno_poller", epoch: epoch
    if dynos.newer_than?(epoch)
      dyno_restart_completed
      unlock
    elsif expired?
      dyno_restart_failed
      unlock
    else
      requeue
    end
  end

  def dynos
    @dynos ||= app.dynos
  end

  def app
    @app ||= Escobar::Heroku::App.new(escobar_client, app_id)
  end

  def expired?
    30.minutes.ago.utc > epoch
  end

  private

  def requeue
    DynoPollerJob.set(wait: 10.seconds).perform_later(args)
  end

  def unlock
    Lock.new(app.cache_key).unlock
  end

  def dyno_restart_completed
    payload = {
      state: "success",
      target_url:  build_url,
      description: "All dynos successfully restarted."
    }

    pipeline.create_deployment_status(deployment_url, payload)
  end

  def dyno_restart_failed
    payload = {
      state: "failure",
      target_url:  build_url,
      description: "All dynos didn't restart within 30 minutes of release."
    }

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

  def build_url
    "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{build_id}"
  end
end
