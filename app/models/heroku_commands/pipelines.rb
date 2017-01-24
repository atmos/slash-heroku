module HerokuCommands
  # Class for handling pipeline requests
  class Pipelines < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "pipelines - View available pipelines.",
        "pipelines:info -a PIPELINE - View detailed information for a pipeline."
      ]
    end

    def run
      @response = run_on_subtask
    rescue StandardError => e
      raise e if Rails.env.test?
      Raven.capture_exception(e)
      response_for("Unable to fetch pipeline info for #{pipeline_name}.")
    end

    def default_pipelines_for_user
      if available_pipelines
        {
          attachments: [
            { text: "You can deploy: #{available_pipelines
              .app_names.join(', ')}." }
          ]
        }
      else
        response_for("You're not authenticated with GitHub yet. " \
                     "<#{command.github_auth_url}|Fix that>.")
      end
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
        default_pipelines_for_user
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

    def pipeline_info
      Responses::PipelineInfo.new(pipeline, pipeline_name).response
    end

    def pipeline
      user.pipeline_for(pipeline_name)
    end

    def available_pipelines
      user.pipelines
    end

    def pipeline_name
      application
    end
  end
end
