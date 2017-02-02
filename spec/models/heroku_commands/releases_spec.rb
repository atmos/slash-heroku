require "rails_helper"

RSpec.describe HerokuCommands::Releases, type: :model do
  include Helpers::Command::Pipelines

  before do
    Timecop.freeze(Time.zone.local(2016, 3, 13))
  end

  after do
    Timecop.return
  end

  # rubocop:disable Metrics/LineLength
  it "has a releases command with default environment" do
    command = command_for("releases slash-heroku in staging")
    command.user.github_token = SecureRandom.hex(24)
    command.user.save

    stub_pipelines_command(command.user.heroku_token)

    response_info = fixture_data("api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases")
    stub_request(:get, "https://api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
    stub_request(:get, "https://api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
    stub_request(:get, "https://api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/deployments")
      .to_return(status: 200, body: response_info)

    expect(command.task).to eql("releases")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Releases.new(command)

    heroku_command.run

    expect(heroku_command.environment).to eql("staging")
    expect(heroku_command.response[:response_type]).to eql("in_channel")
    expect(heroku_command.response[:attachments].size).to eql(1)
    attachment = heroku_command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Latest releases for Heroku pipeline slash-heroku")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text].split("\n").size).to eql(10)
    expect(attachment[:title])
      .to eql("<https://dashboard.heroku.com/pipelines/slash-heroku|slash-heroku> - Recent staging releases")
    expect(attachment[:title_link]).to eql(nil)
    expect(attachment[:fields]).to eql(nil)
  end

  it "has a releases command with specific environment" do
    command = command_for("releases slash-heroku")
    command.user.github_token = SecureRandom.hex(24)
    command.user.save

    stub_pipelines_command(command.user.heroku_token)

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases")
    stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
    stub_request(:get, "https://api.heroku.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
    stub_request(:get, "https://api.heroku.com/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/deployments")
      .to_return(status: 200, body: response_info)

    expect(command.task).to eql("releases")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Releases.new(command)

    heroku_command.run

    expect(heroku_command.environment).to eql("production")
    expect(heroku_command.response[:response_type]).to eql("in_channel")
    expect(heroku_command.response[:attachments].size).to eql(1)
    attachment = heroku_command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Latest releases for Heroku pipeline slash-heroku")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text].split("\n").size).to eql(10)
    expect(attachment[:title])
      .to eql("<https://dashboard.heroku.com/pipelines/slash-heroku|slash-heroku> - Recent production releases")
    expect(attachment[:title_link]).to eql(nil)
    expect(attachment[:fields]).to eql(nil)
  end
  # rubocop:enable Metrics/LineLength
end
