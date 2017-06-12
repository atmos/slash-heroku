module HerokuCommands
  # Class for handling pipeline requests
  class Pipelines < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "pipelines - View available pipelines.",
        "pipelines:info PIPELINE - View detailed information for a pipeline."
      ]
    end

    def run
      run_on_subtask
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
        response_for("No pipelines to deploy")
      end
    end

    def pipeline_information
      pipeline_info
    end

    def run_on_subtask
      case subtask
      when "info"
        if pipeline_name && !pipeline
          response_for("Unable to find a pipeline called #{pipeline_name}")
        else
          pipeline_information
        end
      else
        default_pipelines_for_user
      end
    rescue Escobar::GitHub::RepoNotFound => e
      Raven.capture_exception(e)
      unable_to_access_repository_response
    end

    def unable_to_access_repository_response
      response_for("Unable to access this GitHub repository. " \
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
      pipelines_match[:pipeline_name]
    end

    def pipelines_match
      command.command_text.match(pipelines_pattern)
    end

    def pipelines_pattern
      /
        pipelines(?::[^\s]+)
        \s
        (?<pipeline_name>[-_\.0-9a-zA-Z]+) # Pipeline name
      /x
    end
  end
end
