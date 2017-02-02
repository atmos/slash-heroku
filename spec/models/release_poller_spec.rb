require "rails_helper"

RSpec.describe ReleasePoller, type: :model do
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

  let(:release_args) do
    {
      app_name: "slash-h-production",
      app_id: "b0deddbf-cf56-48e4-8c3a-3ea143be2333",
      build_id: "b80207dc-139f-4546-aedc-985d9cfcafab",
      release_id: "23fe935d-88c8-4fd0-b035-10d44f3d9059",
      deployment_url: deployment_url,
      user_id: user.id,
      pipeline_name: "slash-heroku"
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
    stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/builds/#{build_id}") # rubocop:disable Metrics/LineLength
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

  def stub_release_with_id(release_id)
    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases/#{release_id}") # rubocop:disable Metrics/LineLength
    stub_release_with_id_and_response(release_id, response_info)
  end

  def stub_pending_release_with_id(release_id)
    response_info = fixture_data("api.heroku.com/releases/pending")
    stub_release_with_id_and_response(release_id, response_info)
  end

  def stub_release_with_id_and_response(release_id, response_info)
    stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases/#{release_id}") # rubocop:disable Metrics/LineLength
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})
  end

  it "successfully polls a release" do
    stub_pipelines_info
    stub_build_with_id(release_args[:build_id])
    stub_kolkrabbi_repository
    stub_release_with_id(release_args[:release_id])
    stub_status_creation(deployment_url)

    poller = ReleasePoller.run(release_args)
    expect(poller.release.status).to eql("succeeded")
  end

  it "retry later if release is pending" do
    stub_pipelines_info
    stub_build_with_id(release_args[:build_id])
    stub_kolkrabbi_repository
    stub_pending_release_with_id(release_args[:release_id])

    status_update = stub_status_creation(deployment_url)

    poller = nil
    ActiveJob::Base.queue_adapter = :test
    expect do
      poller = ReleasePoller.run(release_args)
    end.to have_enqueued_job(ReleasePollerJob)
    expect(status_update).to_not have_been_requested
    expect(poller.release.status).to eql("pending")
  end

  it "unlocks the app if the release succeeds" do
    stub_pipelines_info
    stub_build_with_id(release_args[:build_id])
    stub_kolkrabbi_repository
    stub_release_with_id(release_args[:release_id])
    stub_status_creation(deployment_url)

    poller = ReleasePoller.new(release_args)
    lock = Lock.new(poller.release.app.cache_key)
    lock.lock
    poller.run
    expect(lock).to_not be_locked
  end

  it "retry later if release is pending" do
    stub_pipelines_info
    stub_build_with_id(release_args[:build_id])
    stub_kolkrabbi_repository
    stub_pending_release_with_id(release_args[:release_id])

    poller = ReleasePoller.new(release_args)
    lock = Lock.new(poller.release.app.cache_key)
    lock.lock
    poller.run
    expect(lock).to be_locked
  end
end
