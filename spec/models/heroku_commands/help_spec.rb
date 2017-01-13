require "rails_helper"

RSpec.describe HerokuCommands::Help, type: :model do
  include SlashHeroku::Support::Helpers::Api

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  it "has a default help command" do
    command = heroku_handler_for("help")
    expect(command.task).to eql("help")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql(nil)
    expect { command.run }.to_not raise_error

    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Help commands from the heroku integration")
    expect(attachment[:pretext])
      .to eql("Run /h help releases for task specific help")
    expect(attachment[:text].split("\n").size).to eql(7)
    expect(attachment[:title])
      .to eql("Available heroku help commands:")
    expect(attachment[:title_link])
      .to eql("https://github.com/atmos/slash-heroku#slashheroku-")
  end
end
