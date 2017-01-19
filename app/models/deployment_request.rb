# A incoming deployment requests that's valid and available to release.
class DeploymentRequest
  attr_accessor :command
  def initialize(command)
    @command = command
  end

  delegate :application, :branch, :environment,\
    :forced, :hosts, :second_factor,\
    to: :@command

  delegate :channel_name, :team_id, to: "@command.command"
  delegate :slack_user_id, :slack_user_name, to: "@command.command.user"

  def self.process(command)
    request = new(command)

    request.process
  end

  def command_expired?
    command.command.created_at < 60.seconds.ago
  end

  def custom_payload
    {
      notify: {
        room: channel_name,
        team_id: team_id,
        user: slack_user_id,
        user_name: slack_user_name
      }
    }
  end

  def default_heroku_application
    @default_heroku_application ||=
      pipeline.default_heroku_application(environment)
  end

  def pipeline
    @pipeline ||= command.pipeline
  end

  def heroku_application
    @heroku_application ||= default_heroku_application
  end

  def heroku_build_request
    @heroku_build_request ||= heroku_application.build_request_for(pipeline)
  end

  def handle_escobar_exception(error)
    CommandExecutorJob
      .set(wait: 0.5.seconds)
      .perform_later(command_id: command.command.id) unless command_expired?

    if command.command.processed_at.nil?
      command.error_response_for_escobar(error)
    else
      {}
    end
  end

  def reap_heroku_build(heroku_build)
    DeploymentReaperJob
      .set(wait: 10.seconds)
      .perform_later(heroku_build.to_job_json)
    {}
  end

  # rubocop:disable Metrics/AbcSize
  def process
    heroku_application.preauth(second_factor) if second_factor

    heroku_build = heroku_build_request.create(
      "deploy", environment, branch, forced, custom_payload
    )

    heroku_build.command_id = command.command.id

    reap_heroku_build(heroku_build)
  rescue Escobar::Heroku::BuildRequest::Error => e
    handle_escobar_exception(e)
  rescue StandardError => e
    Raven.capture_exception(e)
    command.error_response_for(e.message)
  end
  # rubocop:enable Metrics/AbcSize
end
