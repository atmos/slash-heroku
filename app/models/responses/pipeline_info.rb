module Responses
  # Chat markup describing a single pipeline
  class PipelineInfo
    attr_reader :pipeline, :pipeline_name

    def initialize(pipeline, pipeline_name)
      @pipeline = pipeline
      @pipeline_name = pipeline_name
    end

    def repo_name
      @repo_name ||= begin
                       pipeline.github_repository
                     rescue Escobar::GitHub::RepoNotFound
                       nil
                     end
    end

    # rubocop:disable Metrics/MethodLength
    def response
      {
        response_type: "in_channel",
        attachments: [
          {
            title: "Pipeline: #{pipeline_name}",
            fallback: "Heroku pipeline #{pipeline_name} (#{repo_name})",
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

    private

    def pipeline_markup
      "<#{pipeline.heroku_permalink}|#{pipeline_name}>"
    end

    def repository_markup
      if repo_name
        "<https://github.com/#{repo_name}|#{repo_name}>"
      else
        "<#{pipeline.heroku_permalink}|" \
          "Connect your pipeline to GitHub>"
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

    def required_contexts_markup
      if pipeline.required_commit_contexts.any?
        pipeline.required_commit_contexts.map do |context|
          "<#{pipeline.default_branch_settings_uri}|#{context}>"
        end.join("\n")
      else
        "<#{pipeline.default_branch_settings_uri}|Add Required Contexts>"
      end
    end
  end
end
