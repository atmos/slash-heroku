# rubocop:disable Metrics/ClassLength
module HerokuCommands
  # Class for handling pipeline requests
  class Pipelines < HerokuCommand
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
      response_for_pipeline(pipeline)
    end

    def pipeline_markup
      "<#{pipeline.heroku_permalink}|#{application}>"
    end

    def repository_markup
      name_with_owner = pipeline.github_repository
      "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
    end

    def required_contexts_markup
      if pipeline.required_commit_contexts.any?
        pipeline.required_commit_contexts.map do |context|
          "<#{pipeline.default_branch_settings_uri}|#{context}>"
        end.join("\n")
      else
        "<#{pipeline.default_branch_settings_uri}|Add Required Contexts>"
      end
    end

    def app_names_for_pipeline_environment(name)
      apps = pipeline.environments[name]
      if apps && apps.any?
        apps.map { |app| app.app.name }.join("\n")
      else
        "<#{pipeline.heroku_permalink}|Create One>"
      end
    end

    # rubocop:disable Metrics/MethodLength
    def response_for_pipeline(pipeline)
      repo_name = pipeline.github_repository
      {
        response_type: "in_channel",
        attachments: [
          {
            title: "Application: #{application}",
            fallback: "Heroku app #{application} (#{repo_name})",
            color: HerokuCommands::HerokuCommand::COLOR,
            fields: [
              {
                title: "Heroku",
                value: pipeline_markup,
                short: true
              },
              {
                title: "GitHub",
                value: repository_markup,
                short: true
              },
              {
                title: "Production Apps",
                value: app_names_for_pipeline_environment("production"),
                short: true
              },
              {
                title: "Staging Apps",
                value: app_names_for_pipeline_environment("staging"),
                short: true
              },
              {
                title: "Required Contexts",
                value: required_contexts_markup,
                short: true
              },
              {
                title: "Default Environment",
                value: pipeline.default_environment,
                short: true
              },
              {
                title: "Default Branch",
                value: pipeline.default_branch,
                short: true
              }
            ]
          }
        ]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def pipeline
      user.pipeline_for(application)
    end

    def available_pipelines
      user.pipelines
    end
  end
end
# rubocop:enable Metrics/ClassLength
