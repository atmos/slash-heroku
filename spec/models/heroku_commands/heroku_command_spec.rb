require "rails_helper"

RSpec.describe HerokuCommands::HerokuCommand, type: :model do
  def heroku_command_for(text)
    command = command_for(text)
    HerokuCommands::HerokuCommand.new(command)
  end

  it "has a auth:whoami command" do
    command = heroku_command_for("auth:whoami")
    expect(command.task).to eql("auth")
    expect(command.subtask).to eql("whoami")
    expect(command.application).to eql(nil)
  end

  it "has a auth:logout command" do
    command = heroku_command_for("auth:logout")
    expect(command.task).to eql("auth")
    expect(command.subtask).to eql("logout")
    expect(command.application).to eql(nil)
  end

  it "has a help command" do
    command = heroku_command_for("help")
    expect(command.task).to eql("help")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql(nil)
  end
end
