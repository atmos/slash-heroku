module HerokuCommands
  # Class for handling Deployment requests
  class Deploy < HerokuCommand
    attr_reader :info
    delegate :pipeline_name, :branch, :forced, :hosts, :second_factor,
      to: :@info

    def initialize(command)
      super(command)

      @info = ChatDeploymentInfo.from_text(command.command_text)
    end

    def self.help_documentation
      [
        "deploy <pipeline>/<branch> to <stage>/<app-name> - " \
        "deploy a branch to a pipeline"
      ]
    end

    def run
      run_on_subtask
    end

    def environment
      @environment ||= info.environment || pipeline.default_environment
    end

    def deploy_application
      if pipeline_missing?
        response_for("Unable to find a pipeline called #{pipeline_name}")
      elsif pipeline_environment_missing?
        response_for(error_message_for_unknown_pipeline_environment)
      elsif github_repository_missing?
        response_for(error_message_for_github_repository_missing)
      else
        DeploymentRequest.process(self)
      end
    end

    def deployment_complete_message(_payload, _sha)
      {}
    end

    def pipeline_missing?
      pipeline_name && pipeline.nil?
    end

    def pipeline_environment_missing?
      pipeline.environments[environment].nil?
    end

    def github_repository_missing?
      pipeline.github_repository.blank?
    end

    def run_on_subtask
      case subtask
      when "default"
        deploy_application
      else
        response_for("deploy:#{subtask} is currently unimplemented.")
      end
    rescue StandardError => e
      raise e if Rails.env.test?
      Raven.capture_exception(e)
      response_for("Unable to fetch deployment info for #{pipeline_name}.")
    end

    def repository_markup(deploy)
      name_with_owner = deploy.github_repository
      "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
    end

    def pipeline
      user.pipeline_for(pipeline_name)
    end

    def error_message_for_unknown_pipeline_environment
      "Unable to find an environment called #{environment}. " \
        "Available environments: #{pipeline.sorted_environments.join(', ')}"
    end

    def error_message_for_github_repository_missing
      "<#{pipeline.heroku_permalink}|Connect your pipeline to GitHub>"
    end
  end
end
