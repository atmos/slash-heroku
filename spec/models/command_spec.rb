require "rails_helper"

RSpec.describe Command, type: :model do
  let(:user) { create_atmos }
  it "creates a command" do
    expect do
      command = user.create_command_for(command_params_for("help"))

      expect(command.task).to eql("help")
      expect(command.subtask).to eql("default")
      expect(command.application).to eql(nil)
    end.to change { Command.count }.from(0).to(1)
  end

  it "handles deeply nested subtasks" do
    command_params = command_params_for("help:me:please:really")
    command = user.create_command_for(command_params)

    expect(command.task).to eql("help")
    expect(command.subtask).to eql("me:please:really")
    expect(command.application).to eql(nil)
  end

  it "handles subtasks properly" do
    command = user.create_command_for(command_params_for("auth:whoami"))

    expect(command.task).to eql("auth")
    expect(command.subtask).to eql("whoami")
    expect(command.application).to eql(nil)
  end
end
