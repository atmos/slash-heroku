module Helpers
  module Api
    def default_heroku_headers(token, version = 3)
      {
        "Accept" => "application/vnd.heroku+json; version=#{version}",
        "Accept-Encoding" => "",
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "User-Agent" => "Faraday v0.9.2"
      }
    end

    def default_github_headers(token)
      {
        "Accept" => "application/vnd.github.loki-preview+json",
        "Authorization" => "token #{token}",
        "Content-Type" => "application/json",
        "User-Agent" => "Faraday v0.9.2"
      }
    end

    def stub_pipelines(pipelines)
      pipelines = pipelines.is_a?(Array) ? pipelines : [pipelines]
      stub_json_request(:get,
                        "https://api.heroku.com/pipelines",
                        pipelines.to_json)
    end

    def stub_couplings(pipeline_id, apps, stage = "production")
      apps = apps.is_a?(Array) ? apps : [apps]
      couplings = apps.map do |app|
        { stage: stage, app: { id: app[:id] } }
      end
      path = "/pipelines/#{pipeline_id}/pipeline-couplings"
      stub_heroku_request(:get, path, couplings.to_json)
    end

    def stub_2fa_check(app_id, args = {})
      locked = args[:locked]
      status = locked ? 403 : 200
      body = locked ? { id: "two_factor" } : {}
      stub_heroku_request(:get,
                          "/apps/#{app_id}/config-vars",
                          body.to_json,
                          status)
    end

    def stub_heroku_app(id, name)
      app = { id: id, name: name }
      stub_heroku_request(:get, "/apps/#{id}", app.to_json)
    end

    def stub_mapping_pipeline_repository(pipeline_id, repo_name_with_owner)
      url = "https://kolkrabbi.com/pipelines/#{pipeline_id}/repository"
      payload = { repository: { name: repo_name_with_owner } }
      stub_json_request(:get, url, payload.to_json)
    end

    def stub_pipeline_repository_not_found(pipeline_id)
      url = "https://kolkrabbi.com/pipelines/#{pipeline_id}/repository"
      stub_json_request(:get, url, {}.to_json, 404)
    end

    def stub_repository(name_with_owner, default_branch = "master")
      stub_github_request(:get,
                          "/repos/#{name_with_owner}",
                          { default_branch: default_branch }.to_json)
    end

    def stub_required_contexts(name_with_owner, branch = "master")
      path = "/repos/#{name_with_owner}/branches/#{branch}"
      stub_github_request(:get, path, {}.to_json)
    end

    def stub_deployment_conflict(repo)
      payload = {
        message: "Conflict: Commit status checks failed for master."
      }
      stub_github_request(:post,
                          "/repos/#{repo}/deployments",
                          payload.to_json,
                          409)
    end

    def stub_deployment_status(repo)
      stub_github_request(:post, "/repos/#{repo}/deployments", {}.to_json)
    end
  end
end
