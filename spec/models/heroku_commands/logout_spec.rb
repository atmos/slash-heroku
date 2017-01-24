require "rails_helper"

RSpec.describe HerokuCommands::Logout, type: :model do
  let(:command) { command_for("logout") }
  let(:heroku_command) { HerokuCommands::Logout.new(command) }

  it "deletes the user and all executed commands" do
    command.user.heroku_token = SecureRandom.hex(32)
    command.user.github_token = SecureRandom.hex(32)
    command.user.save

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    expect(heroku_command.task).to eql("logout")
    expect(heroku_command.subtask).to eql("default")
    expect(heroku_command.application).to eql(nil)

    expect { heroku_command.run }.to_not raise_error

    expect do
      heroku_command.user.reload
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
