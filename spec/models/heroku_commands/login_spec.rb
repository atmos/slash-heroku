require "rails_helper"

RSpec.describe HerokuCommands::Login, type: :model do
  let(:command) { command_for("login") }
  let(:heroku_command) { HerokuCommands::Login.new(command) }

  it "prints the user's email if properly onboarded" do
    command.user.heroku_token = SecureRandom.hex(32)
    command.user.github_token = SecureRandom.hex(32)
    command.user.save

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    expect(heroku_command.task).to eql("login")
    expect(heroku_command.subtask).to eql("default")
    expect(heroku_command.application).to eql(nil)
    expect { heroku_command.run }.to_not raise_error

    response = heroku_command.run
    expect(response[:attachments].size).to eql(1)
    attachment = response[:attachments].first
    expect(attachment[:text]).to match("atmos@atmos.org")
  end

  it "prompts the user to onboard with heroku if not configured" do
    command.user.heroku_token = nil
    command.user.github_token = nil
    command.user.save

    expect(command.task).to eql("login")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql(nil)
    expect { heroku_command.run }.to_not raise_error

    response = heroku_command.run
    expect(response[:attachments].size).to eql(1)
    attachment = response[:attachments].first
    expect(attachment[:text]).to match("sign in to Heroku")
  end

  it "prompts the user to onboard with github if not configured" do
    command.user.heroku_token = SecureRandom.hex(32)
    command.user.github_token = nil
    command.user.save

    expect(command.task).to eql("login")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql(nil)
    expect { heroku_command.run }.to_not raise_error

    response = heroku_command.run
    expect(response[:attachments].size).to eql(1)
    attachment = response[:attachments].first
    expect(attachment[:text]).to match("not authenticated with GitHub yet")
  end
end
