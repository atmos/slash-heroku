require "rails_helper"

RSpec.describe HerokuCommands::Auth, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  it "has a auth:whoami command" do
    command = heroku_handler_for("auth:whoami")

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    expect(command.task).to eql("auth")
    expect(command.subtask).to eql("whoami")
    expect(command.application).to eql(nil)
    expect { command.run }.to_not raise_error

    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:text]).to match("atmos@atmos.org")
  end

  it "has a auth:logout command" do
    command = heroku_handler_for("auth:logout")

    expect(command.task).to eql("auth")
    expect(command.subtask).to eql("logout")
    expect(command.application).to eql(nil)
    expect { command.run }.to_not raise_error

    expect do
      command.user.reload
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
