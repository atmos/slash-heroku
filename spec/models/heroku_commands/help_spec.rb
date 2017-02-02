require "rails_helper"

RSpec.describe HerokuCommands::Help, type: :model do
  it "has a default help command" do
    command = command_for("help")
    expect(command.task).to eql("help")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql(nil)

    heroku_command = HerokuCommands::Help.new(command)

    expect { heroku_command.run }.to_not raise_error

    expect(heroku_command.response[:attachments].size).to eql(1)
    attachment = heroku_command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Help commands from the heroku integration")
    expect(attachment[:pretext])
      .to eql("Run /h help releases for task specific help")
    expect(attachment[:text].split("\n").size).to eql(6)
    expect(attachment[:title])
      .to eql("Available heroku help commands:")
    expect(attachment[:title_link])
      .to eql("https://github.com/atmos/slash-heroku#slashheroku-")
  end
end
