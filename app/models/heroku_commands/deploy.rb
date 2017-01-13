module HerokuCommands
  # Class for handling Deployment requests
  class Deploy < HerokuCommand
    include PipelineResponse

    attr_reader :info
    delegate :application, :branch, :forced, :hosts, :second_factor, to: :@info

    def initialize(command)
      super(command)

      @info = Deployment.from_text(command.command_text)
    end

    def self.help_documentation
      [
        "deploy <pipeline>/<branch> to <stage>/<app-name> - " \
        "deploy a branch to a pipeline"
      ]
    end

    def run
      @response = run_on_subtask
    end

    def environment
      @environment ||= info.environment || pipeline.default_environment
    end

    def deploy_application
      if application && !pipelines[application]
        response_for("Unable to find a pipeline called #{application}")
      else
        DeploymentRequest.process(self)
      end
    end

    def deployment_complete_message(_payload, _sha)
      {}
    end

    def run_on_subtask
      case subtask
      when "default"
        if pipelines
          deploy_application
        else
          response_for("You're not authenticated with GitHub yet. " \
                       "<#{command.github_auth_url}|Fix that>.")
        end
      else
        response_for("deploy:#{subtask} is currently unimplemented.")
      end
    rescue StandardError => e
      raise e if Rails.env.test?
      Raven.capture_exception(e)
      response_for("Unable to fetch deployment info for #{application}.")
    end

    def repository_markup(deploy)
      name_with_owner = deploy.github_repository
      "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
    end
  end
end
