require "rails_helper"

RSpec.describe HerokuCommands::Deploy, type: :model do
  include Helpers::Command::Deploy

  before do
    Lock.clear_deploy_locks!
  end

  def build_command(cmd)
    command = command_for(cmd)
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload
    command
  end

  # rubocop:disable Metrics/LineLength
  it "has a deploy command" do
    command = build_command("deploy hubot to production")

    stub_successful_deployment_flow("hubot")

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response).to be_empty
  end

  it "alerts you if the environment is not found" do
    command = build_command("deploy hubot to mars")

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    stub_missing_environment_flow("hubot", available_env: "production")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response[:response_type]).to eql("in_channel")
    expect(response[:text]).to eql(
      "Unable to find an environment called mars. " \
      "Available environments: production"
    )
  end

  it "responds to you if required commit statuses aren't present" do
    command = build_command("deploy hubot to production")

    pipeline_name = "hubot"
    app_name = "hubot1"
    repo = "atmos/hubot"

    stub_missing_required_commit_status_flow(pipeline_name, app_name, repo)

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
    command = build_command("deploy hubot to production")

    pipeline_name = "hubot"
    app_name = "hubot1"

    stub_2fa_locked_app_flow(pipeline_name, app_name)

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response[:text]).to be_nil
    expect(response[:response_type]).to be_nil
    attachments = [
      {
        text: "<https://dashboard.heroku.com/apps/hubot1|hubot1> " \
        "requires a second factor for access."
      }
    ]
    expect(response[:attachments]).to eql(attachments)
  end

  it "locks on second attempt" do
    command = command_for("deploy hubot to production")
    heroku_command = HerokuCommands::Deploy.new(command)
    heroku_command.user.github_token = SecureRandom.hex
    heroku_command.user.save

    pipeline_name = "hubot"
    app_name = "hubot1"

    stub_locked_deployment_flow(pipeline_name, app_name)

    response = heroku_command.run

    attachments = [
      {
        text: "Someone is already deploying to hubot1",
        color: "#f00"
      }
    ]
    expect(response[:attachments]).to eql(attachments)
  end

  it "responds with an error message if the pipeline is not connected to GitHub" do
    command = command_for("deploy hubot to production")
    heroku_command = HerokuCommands::Deploy.new(command)
    heroku_command.user.github_token = SecureRandom.hex
    heroku_command.user.save

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    pipeline_id = SecureRandom.uuid
    stub_pipeline_not_connected_to_github_flow(pipeline_id, "hubot")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(response[:response_type]).to eql("in_channel")
    expect(response[:text]).to eql(
      "<https://dashboard.heroku.com/pipelines/" \
      "#{pipeline_id}|Connect your pipeline to GitHub>"
    )
  end

  it "responds with an error message if the pipeline contains more than one app" do
    command = build_command("deploy hubot to production")

    stub_multiple_apps_in_stage_flow(
      pipeline_name: "hubot",
      app_names: %w{hubot1 hubot2}
    )

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    attachments = [
      {
        text: "There is more than one app in the hubot production stage: hubot1, hubot2. This is not supported yet.",
        color: "#f00"
      }
    ]
    expect(response[:attachments]).to eql(attachments)
  end

  it "deploys an application if the pipeline has multiple apps and an app is specified" do
    command = build_command("deploy hubot to production/hubot1")

    stub_multiple_apps_in_stage_flow(
      pipeline_name: "hubot",
      app_names: %w{hubot1 hubot2},
      chosen_app_name: "hubot1",
      repo: "atmos/hubot"
    )

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response).to be_empty
  end
end
