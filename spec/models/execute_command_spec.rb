require "rails_helper"

RSpec.describe ExecuteCommand, type: :model do
  include Helpers::Command::Pipelines

  describe "Pipelines command" do
    it "lists available pipelines" do
      command = command_for("pipelines")
      command.user.github_token = SecureRandom.hex(24)
      command.user.save

      stub_pipelines_command(command.user.heroku_token)

      slack_body = {
        attachments:
          [
            {
              text: "You can deploy: hubot, slash-heroku."
            }
          ]
      }.to_json

      stub = stub_slack_request(slack_body)

      ExecuteCommand.for(command)

      expect(stub).to have_been_requested
    end
  end
end
