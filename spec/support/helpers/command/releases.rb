module Helpers
  module Command
    module Releases
      # rubocop:disable Metrics/LineLength
      # rubocop:disable Metrics/AbcSize
      def stub_releases(heroku_token, app_id = "760bc95e-8780-4c76-a688-3a4af92a3eee")
        response_info = fixture_data("api.heroku.com/apps/#{app_id}/releases")
        stub_request(:get, "https://api.heroku.com/apps/#{app_id}/releases")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})

        response_info = fixture_data("api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
        stub_request(:get, "https://api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})

        response_info = fixture_data("api.heroku.com/apps/#{app_id}")
        stub_request(:get, "https://api.heroku.com/apps/#{app_id}")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})

        response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
        stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
          .to_return(status: 200, body: response_info)

        response_info = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments")
        stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/deployments")
          .to_return(status: 200, body: response_info)
      end
      # rubocop:enable Metrics/LineLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
