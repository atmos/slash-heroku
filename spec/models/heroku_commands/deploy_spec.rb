require "rails_helper"

RSpec.describe HerokuCommands::Deploy, type: :model do
  include Helpers::Command::Deploy

  before do
    Lock.clear_deploy_locks!
  end

  # rubocop:disable Metrics/LineLength
  it "has a deploy command" do
    command = command_for("deploy hubot to production")
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload

    stub_deploy_command(command.user.heroku_token)

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response).to be_empty
  end

  it "responds to you if required commit statuses aren't present" do
    command = command_for("deploy hubot to production")
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload

    heroku_token = command.user.heroku_token

    stub_account_info(heroku_token)
    stub_pipeline_info(heroku_token)
    stub_app_info(heroku_token)
    stub_app_is_not_2fa(heroku_token)
    stub_build(heroku_token)

    stub_request(:post, "https://api.github.com/repos/atmos/hubot/deployments")
      .to_return(status: 409, body: { message: "Conflict: Commit status checks failed for master." }.to_json, headers: {})

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response[:response_type]).to eql("in_channel")
    expect(response[:text]).to be_nil
    expect(response[:attachments].size).to eql(1)
    attachment = response[:attachments].first
    expect(attachment[:text]).to eql(
      "Unable to create GitHub deployments for atmos/hubot: " \
      "Conflict: Commit status checks failed for master."
    )
  end

  it "prompts to unlock in the dashboard if the app is 2fa protected" do
    command = command_for("deploy hubot to production")
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload

    heroku_token = command.user.heroku_token

    stub_account_info(heroku_token)
    stub_pipeline_info(heroku_token)
    stub_app_info(heroku_token)

    stub_request(:get, "https://api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa/config-vars")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 403, body: { id: "two_factor" }.to_json, headers: {})

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response[:text]).to be_nil
    expect(response[:response_type]).to be_nil
    attachments = [
      { text: "<https://dashboard.heroku.com/apps/hubot|Unlock hubot>" }
    ]
    expect(response[:attachments]).to eql(attachments)
  end

  it "locks on second attempt" do
    command = command_for("deploy hubot to production")
    heroku_command = HerokuCommands::Deploy.new(command)
    heroku_command.user.github_token = SecureRandom.hex(24)
    heroku_command.user.save

    heroku_token = command.user.heroku_token

    stub_pipeline_info(heroku_token)
    stub_app_info(heroku_token)

    # Fake the lock
    Lock.new("escobar-app-27bde4b5-b431-4117-9302-e533b887faaa").lock

    response = heroku_command.run

    attachments = [
      {
        text: "Someone is already deploying to hubot",
        color: "#f00"
      }
    ]
    expect(response[:attachments]).to eql(attachments)
  end
end
