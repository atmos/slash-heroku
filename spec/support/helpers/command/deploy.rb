module Helpers
  module Command
    module Deploy
      def stub_pipeline_not_connected_to_github_flow(pipeline_id, pipeline_name)
        pipeline =  { id: pipeline_id, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: pipeline_name }

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app)

        stub_pipeline_repository_not_found(pipeline[:id])
      end

      def stub_missing_required_commit_status_flow(pipeline_name,
                                                   app_name,
                                                   repo)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: app_name }

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app)
        stub_2fa_check(app[:id])
        stub_heroku_app(app[:id], app[:name])

        stub_mapping_pipeline_repository(pipeline[:id], repo)

        stub_repository(repo)
        stub_required_contexts(repo)

        stub_deployment_conflict(repo)
      end

      def stub_missing_environment_flow(pipeline_name, environments)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: pipeline_name }

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app, environments[:available_env])
      end

      def stub_2fa_locked_app_flow(pipeline_name, app_name)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: app_name }

        stub_pipelines(pipeline)

        stub_mapping_pipeline_repository(pipeline[:id], "heroku/#{app_name}")

        stub_couplings(pipeline[:id], app)
        stub_heroku_app(app[:id], app[:name])
        stub_2fa_check(app[:id], locked: true)
      end

      def stub_locked_deployment_flow(pipeline_name, app_name)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: app_name }

        stub_pipelines(pipeline)

        stub_mapping_pipeline_repository(pipeline[:id], "heroku/#{app_name}")

        stub_couplings(pipeline[:id], app)
        stub_heroku_app(app[:id], app[:name])
        stub_2fa_check(app[:id])

        # Fake the lock
        Lock.new("escobar-app-#{app[:id]}").lock
      end

      def stub_multiple_apps_in_stage_flow(args = {})
        pipeline_name   = args[:pipeline_name]
        app_names       = args[:app_names]
        chosen_app_name = args[:chosen_app_name]
        repo            = args.fetch(:repo, "atmos/hubot")
        pipeline_id     = SecureRandom.uuid

        pipeline = { id: pipeline_id, name: pipeline_name }

        stub_mapping_pipeline_repository(pipeline_id, repo)

        apps = stubbed_apps_hash_from_names(app_names)

        stub_pipelines(pipeline)
        stub_couplings(pipeline_id, apps)

        return unless chosen_app_name
        chosen_app = apps.detect { |app| app[:name] == chosen_app_name }

        stub_chosen_app(chosen_app, repo, pipeline_id)
      end

      def stub_chosen_app(chosen_app, repo, pipeline_id)
        stub_2fa_check(chosen_app[:id])
        stub_mapping_pipeline_repository(pipeline_id, repo)

        stub_repository(repo)
        stub_required_contexts(repo)
        stub_deployment_status(repo)
      end

      def stubbed_apps_hash_from_names(app_names)
        app_names.map do |app_name|
          id = SecureRandom.uuid
          stub_heroku_app(id, app_name)
          { id: id, name: app_name }
        end
      end

      def stub_successful_deployment_flow(pipeline_name)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: pipeline_name }
        repo = "heroku/#{pipeline_name}"

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app)
        stub_heroku_app(app[:id], app[:name])
        stub_2fa_check(app[:id])
        stub_mapping_pipeline_repository(pipeline[:id], repo)

        stub_repository(repo)
        stub_required_contexts(repo)
        stub_deployment_status(repo)
      end

      # rubocop:enable Metrics/LineLength
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
