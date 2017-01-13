require "rails_helper"

RSpec.describe Deployment, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  it "has a deploy:info command" do
    expect(Deployment.from_text("ping")).to_not be_valid
    expect(Deployment.from_text("image me pugs")).to_not be_valid
  end

  it "handles simple deployment" do
    model = Deployment.from_text("deploy hubot")
    expect(model).to be_valid
    expect(model).to_not be_forced
    expect(model.application).to eql("hubot")
    expect(model.environment).to be_nil
    expect(model.hosts).to be_nil
    expect(model.second_factor).to be_nil
  end

  it "handles ! operations" do
    model = Deployment.from_text("deploy! hubot")
    expect(model).to be_valid
    expect(model).to be_forced
  end

  it "handles custom tasks" do
    model = Deployment.from_text("deploy:migrate hubot")
    expect(model).to be_valid
    expect(model.task).to eql("deploy:migrate")
  end

  it "handles deploying branches" do
    model = Deployment.from_text("deploy hubot/mybranch")
    expect(model).to be_valid
    expect(model.branch).to eql("mybranch")
  end

  it "handles deploying to environments" do
    model = Deployment.from_text("deploy hubot to production")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
  end

  it "handles deploying to environments with hosts" do
    model = Deployment.from_text("deploy hubot to production/fe1,fe2")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.hosts).to eql("fe1,fe2")
  end

  # rubocop:disable Metrics/LineLength
  it "handles deploying branches to environments with hosts" do
    model = Deployment.from_text("deploy hubot/atmos/branch to production/fe1,fe2")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.hosts).to eql("fe1,fe2")
    expect(model.branch).to eql("atmos/branch")
  end

  it "handles deploying branches to environments with hosts plus yubikeys" do
    model = Deployment.from_text("deploy hubot/atmos/branch to production/fe1,fe2 ccccccdlnncbtuevhdbctrccukdciveuclhbkvehbeve")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.hosts).to eql("fe1,fe2")
    expect(model.branch).to eql("atmos/branch")
    expect(model.second_factor).to eql("ccccccdlnncbtuevhdbctrccukdciveuclhbkvehbeve")
  end

  it "handles deploying branches to environments with hosts plus authenticator tokens" do
    model = Deployment.from_text("deploy hubot/atmos/branch to production/fe1,fe2 123456")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.hosts).to eql("fe1,fe2")
    expect(model.branch).to eql("atmos/branch")
    expect(model.second_factor).to eql("123456")
  end

  it "doesn't match on malformed yubikeys" do
    model = Deployment.from_text("deploy hubot/atmos/branch to production/fe1,fe2 burgers")
    expect(model).to_not be_valid
  end

  it "doesn't match typos" do
    model = Deployment.from_text("deploy hubot/atmos/branch tos taging")
    expect(model).to_not be_valid
  end
  # rubocop:enable Metrics/LineLength
end
