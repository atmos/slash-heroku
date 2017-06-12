require "rails_helper"

RSpec.describe HerokuCommands::Releases, type: :model do
  include Helpers::Command::Pipelines
  include Helpers::Command::Releases

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
    stub_releases(command.user.heroku_token)

    expect(command.task).to eql("releases")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Releases.new(command)

    response = heroku_command.run

    expect(heroku_command.environment).to eql("staging")
    expect(response[:response_type]).to eql("in_channel")
    expect(response[:attachments].size).to eql(1)
    attachment = response[:attachments].first
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

    production_app_id = "b0deddbf-cf56-48e4-8c3a-3ea143be2333"
    stub_releases(command.user.heroku_token, production_app_id)

    expect(command.task).to eql("releases")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Releases.new(command)

    response = heroku_command.run

    expect(heroku_command.environment).to eql("production")
    expect(response[:response_type]).to eql("in_channel")
    expect(response[:attachments].size).to eql(1)
    attachment = response[:attachments].first
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
