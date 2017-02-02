require "rails_helper"

RSpec.describe HerokuCommands::Pipelines, type: :model do
  include Helpers::Command::Pipelines

  def not_found_response
    {
      message: "Not Found",
      documentation_url: "https://developer.github.com/v3"
    }.to_json
  end

  it "lists available pipelines" do
    command = command_for("pipelines")
    command.user.github_token = SecureRandom.hex(24)
    command.user.save

    stub_pipelines_command(command.user.heroku_token)

    expect(command.task).to eql("pipelines")
    expect(command.subtask).to eql("default")
    expect(command.application).to be_nil

    heroku_command = HerokuCommands::Pipelines.new(command)

    heroku_command.run

    expect(heroku_command.response[:response_type]).to be_nil
    expect(heroku_command.response[:attachments].size).to eql(1)
    attachment = heroku_command.response[:attachments].first
    expect(attachment[:text]).to eql(
      "You can deploy: hubot, slash-heroku."
    )
  end

  # rubocop:disable Metrics/LineLength
  it "has a pipeline:info command" do
    command = command_for("pipelines:info hubot")
    command.user.github_token = SecureRandom.hex(24)
    command.user.save

    stub_pipeline_info_command(command.user.heroku_token, command.user.github_token)

    expect(command.task).to eql("pipelines")
    expect(command.subtask).to eql("info")

    heroku_command = HerokuCommands::Pipelines.new(command)

    heroku_command.run

    expect(heroku_command.response[:response_type]).to eql("in_channel")
    expect(heroku_command.response[:attachments].size).to eql(1)
    attachment = heroku_command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Heroku app hubot (atmos/hubot)")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text]).to be_nil
    expect(attachment[:title]).to eql("Application: hubot")
    expect(attachment[:title_link]).to eql(nil)

    heroku_cell = attachment[:fields][0]
    expect(heroku_cell).to_not be_nil
    expect(heroku_cell[:title]).to eql("Heroku")
    expect(heroku_cell[:value]).to eql("<https://dashboard.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111|hubot>")

    github_cell = attachment[:fields][1]
    expect(github_cell).to_not be_nil
    expect(github_cell[:title]).to eql("GitHub")
    expect(github_cell[:value]).to eql("<https://github.com/atmos/hubot|atmos/hubot>")

    production_cell = attachment[:fields][2]
    expect(production_cell).to_not be_nil
    expect(production_cell[:title]).to eql("Production Apps")
    expect(production_cell[:value]).to eql("hubot")

    staging_cell = attachment[:fields][3]
    expect(staging_cell).to_not be_nil
    expect(staging_cell[:title]).to eql("Staging Apps")
    expect(staging_cell[:value]).to eql("<https://dashboard.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111|Create One>")

    required_contexts_cell = attachment[:fields][4]
    expect(required_contexts_cell).to_not be_nil
    expect(required_contexts_cell[:title]).to eql("Required Contexts")
    expect(required_contexts_cell[:value])
      .to eql("<https://github.com/atmos/hubot/settings/branches/production|Add Required Contexts>")

    environment_cell = attachment[:fields][5]
    expect(environment_cell).to_not be_nil
    expect(environment_cell[:title]).to eql("Default Environment")
    expect(environment_cell[:value]).to eql("production")

    branch_cell = attachment[:fields][6]
    expect(branch_cell).to_not be_nil
    expect(branch_cell[:title]).to eql("Default Branch")
    expect(branch_cell[:value]).to eql("production")
  end

  it "tells you to login to GitHub if pipeline:info can't auth" do
    command = command_for("pipelines:info hubot")
    command.user.github_token = SecureRandom.hex(24)
    command.user.save

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
    stub_request(:get, "https://api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
    stub_request(:get, "https://api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
      .to_return(status: 200, body: response_info)

    stub_request(:get, "https://api.github.com/repos/atmos/hubot")
      .with(headers: default_github_headers(command.user.github_token))
      .to_return(status: 404, body: not_found_response, headers: {})

    stub_request(:get, "https://api.github.com/repos/atmos/hubot/branches/master")
      .to_return(status: 404, body: not_found_response, headers: {})

    expect(command.task).to eql("pipelines")
    expect(command.subtask).to eql("info")

    heroku_command = HerokuCommands::Pipelines.new(command)

    heroku_command.run

    response = heroku_command.response
    expect(response[:response_type]).to eql("in_channel")
    expect(response[:text]).to include("You're not authenticated with GitHub.")
  end
  # rubocop:enable Metrics/LineLength
end
