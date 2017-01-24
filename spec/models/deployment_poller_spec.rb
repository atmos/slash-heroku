require "rails_helper"

RSpec.describe DeploymentPoller, type: :model do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:user) do
    u = create_atmos
    u.heroku_token = SecureRandom.hex(24)
    u.heroku_refresh_token = SecureRandom.hex(16)
    u.heroku_expires_at = 15.minutes.from_now
    u.github_token = SecureRandom.hex(24)
    u.save
    u
  end

  let(:deployment_url) do
    "https://api.github.com/repos/atmos/slash-heroku/deployments/123456"
  end

  let(:build_args) do
    {
      sha: "abcdefg",
      repo: "heroku/slash-heroku",
      app_name: "slash-h-production",
      build_id: "b80207dc-139f-4546-aedc-985d9cfcafab",
      deployment_url: deployment_url,
      user_id: user.id,
      name: "slash-heroku"
    }
  end

  def stub_pipelines_info
    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})
  end

  def stub_build_with_id(build_id)
    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/builds/#{build_id}") # rubocop:disable Metrics/LineLength
    stub_build_with_id_and_response(build_id, response_info)
  end

  def stub_pending_build_with_id(build_id)
    response_info = fixture_data("api.heroku.com/builds/pending")
    stub_build_with_id_and_response(build_id, response_info)
  end

  def stub_completed_build_without_release_with_id(build_id)
    response_info = fixture_data("api.heroku.com/builds/completed_without_release") # rubocop:disable Metrics/LineLength
    stub_build_with_id_and_response(build_id, response_info)
  end

  def stub_build_with_id_and_response(build_id, response_info)
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/builds/#{build_id}") # rubocop:disable Metrics/LineLength
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})
  end

  def stub_kolkrabbi_repository
    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository") # rubocop:disable Metrics/LineLength
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository") # rubocop:disable Metrics/LineLength
      .to_return(status: 200, body: response_info)
  end

  def stub_status_creation(deployment_url)
    stub_request(:post, "#{deployment_url}/statuses")
      .to_return(status: 200, body: {}.to_json, headers: {})
  end

  it "successfully polls a build with a release" do
    stub_pipelines_info
    stub_build_with_id(build_args[:build_id])
    stub_kolkrabbi_repository
    stub_status_creation(deployment_url)

    poller = nil
    expect do
      poller = DeploymentPoller.run(build_args)
    end.to have_enqueued_job(ReleasePollerJob)
    expect(poller.build.status).to eql("succeeded")
    expect(poller.build).to be_releasing
  end

  it "re enqueue if build is still pending" do
    stub_pipelines_info
    stub_pending_build_with_id(build_args[:build_id])

    poller = nil
    expect do
      poller = DeploymentPoller.run(build_args)
    end.to have_enqueued_job(DeploymentPollerJob)
    expect(poller.build.status).to eql("pending")
  end

  it "updates status if build is complete without release" do
    stub_pipelines_info
    stub_completed_build_without_release_with_id(build_args[:build_id])
    stub_kolkrabbi_repository
    status_request = stub_status_creation(deployment_url)

    poller = nil
    expect do
      poller = DeploymentPoller.run(build_args)
    end.to_not have_enqueued_job(ReleasePollerJob)
    expect(poller.build.status).to eql("succeeded")
    expect(poller.build).to_not be_releasing
    expect(status_request).to have_been_requested
  end
end
