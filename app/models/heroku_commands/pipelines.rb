module HerokuCommands
  # Class for handling pipeline requests
  class Pipelines < HerokuCommand
    include PipelineResponse

    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "pipelines - View available pipelines.",
        "pipelines:info -a APP - View detailed information for a pipeline."
      ]
    end

    def run
      @response = run_on_subtask
    rescue StandardError => e
      raise e if Rails.env.test?
      Raven.capture_exception(e)
      response_for("Unable to fetch pipeline info for #{application}.")
    end

    def run_on_subtask
      case subtask
      when "info"
        if pipeline.configured?
          pipeline_info
        else
          {
            attachments: [
              { text: "<#{pipeline.heroku_permalink}|" \
                      "Connect your pipeline to GitHub>" }
            ]
          }
        end
      when "list", "default"
        {
          attachments: [
            { text: "You can deploy: #{pipelines.app_names.join(', ')}." }
          ]
        }
      else
        response_for("pipeline:#{subtask} is currently unimplemented.")
      end
    rescue Escobar::GitHub::RepoNotFound
      unable_to_access_repository_response
    end

    def unable_to_access_repository_response
      response_for("You're not authenticated with GitHub. " \
                   "<#{command.github_auth_url}|Fix that>.")
    end
  end
end
