module Helpers
  module Command
    module Pipelines
      def stub_pipelines_command(heroku_token)
        response_info = fixture_data("api.heroku.com/account/info")
        stub_request(:get, "https://api.heroku.com/account")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})

        response_info = fixture_data("api.heroku.com/pipelines/info")
        stub_request(:get, "https://api.heroku.com/pipelines")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})
      end

      # rubocop:disable Metrics/LineLength
      # rubocop:disable Metrics/AbcSize
      def stub_pipeline_info_command(heroku_token, github_token)
        stub_pipelines_command(heroku_token)

        response_info =
          fixture_data("api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
        stub_request(:get, "https://api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})

        response_info = fixture_data("api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
        stub_request(:get, "https://api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})

        response_info = fixture_data("kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
        stub_request(:get, "https://kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
          .to_return(status: 200, body: response_info)

        response = fixture_data("api.github.com/repos/atmos/hubot/index")
        stub_request(:get, "https://api.github.com/repos/atmos/hubot")
          .with(headers: default_github_headers(github_token))
          .to_return(status: 200, body: response, headers: {})

        response_info = fixture_data("api.github.com/repos/atmos/hubot/branches/production")
        stub_request(:get, "https://api.github.com/repos/atmos/hubot/branches/production")
          .to_return(status: 200, body: response_info, headers: {})
      end
      # rubocop:enable Metrics/LineLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
