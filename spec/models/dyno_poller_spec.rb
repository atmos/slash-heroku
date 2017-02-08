require "rails_helper"

RSpec.describe DynoPoller, type: :model do
  after do
    Timecop.return
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

  let(:dyno_args) do
    {
      app_name: "slash-h-production",
      app_id: "b0deddbf-cf56-48e4-8c3a-3ea143be2333",
      build_id: "b80207dc-139f-4546-aedc-985d9cfcafab",
      release_id: "23fe935d-88c8-4fd0-b035-10d44f3d9059",
      deployment_url: deployment_url,
      user_id: user.id,
      epoch: 1.minute.ago.utc.to_s,
      pipeline_name: "slash-heroku"
    }
  end

  def stub_pipelines_info
    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
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

  it "successfully polls dyno restarts" do
    stub_pipelines_info
    stub_kolkrabbi_repository
    stub_status_creation(deployment_url)

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/dynos") # rubocop:disable Metrics/LineLength
    stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/dynos") # rubocop:disable Metrics/LineLength
      .to_return(status: 200, body: response_info)

    # Timecop.freeze(Time.zone.utc(2017, 2, 6, 18, 0, 0))
    Timecop.return

    poller = DynoPoller.run(dyno_args)
    expect(poller).to_not be_expired

    poller = DynoPoller.run(dyno_args.merge(epoch: 31.minutes.ago.utc.to_s))
    expect(poller).to be_expired
  end
end
