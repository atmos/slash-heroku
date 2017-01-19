require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { create_atmos }

  it "creates action made by the user" do
    expect do
      params = action_params_for("environment", "staging")
      user.create_message_action_for(params)
    end.to change(user.message_actions, :count).by(1)
    action = MessageAction.last
    expect(action.value).to eql("staging")
    expect(action.callback_id).to eql("environment")
    expect(action.team_id).to eql("T0QQTP89F")
    expect(action.team_domain).to eql("heroku")
    expect(action.channel_id).to eql("C0QQS2U6B")
    expect(action.channel_name).to eql("general")
    expect(action.action_ts).to eql("1480454458.026997")
    expect(action.message_ts).to eql("1480454212.000005")
  end

  describe "onboarding" do
    it "requires a non-empty github_token" do
      user.github_token = SecureRandom.hex(24)

      expect(user).to be_github_configured
      expect(user).to_not be_onboarded
    end

    it "require a non-empty heroku_token" do
      user.heroku_token = SecureRandom.hex(24)

      expect(user).to be_heroku_configured
      expect(user).to_not be_onboarded
    end

    it "is complete if a github and heroku are configured" do
      user.heroku_token = SecureRandom.hex(24)
      user.github_token = SecureRandom.hex(24)

      expect(user).to be_onboarded
    end
  end
end
