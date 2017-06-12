require "rails_helper"

RSpec.describe ChatDeploymentInfo, type: :model do
  it "has a deploy:info command" do
    expect(ChatDeploymentInfo.from_text("ping")).to_not be_valid
    expect(ChatDeploymentInfo.from_text("image me pugs")).to_not be_valid
  end

  it "handles simple deployment" do
    model = ChatDeploymentInfo.from_text("deploy hubot")
    expect(model).to be_valid
    expect(model).to_not be_forced
    expect(model.pipeline_name).to eql("hubot")
    expect(model.environment).to be_nil
    expect(model.application).to be_nil
    expect(model.second_factor).to be_nil
  end

  it "handles ! operations" do
    model = ChatDeploymentInfo.from_text("deploy! hubot")
    expect(model).to be_valid
    expect(model).to be_forced
  end

  it "handles custom tasks" do
    model = ChatDeploymentInfo.from_text("deploy:migrate hubot")
    expect(model).to be_valid
    expect(model.task).to eql("deploy:migrate")
  end

  it "handles deploying branches" do
    model = ChatDeploymentInfo.from_text("deploy hubot/mybranch")
    expect(model).to be_valid
    expect(model.branch).to eql("mybranch")
  end

  it "handles deploying to environments" do
    model = ChatDeploymentInfo.from_text("deploy hubot to production")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
  end

  it "handles deploying to environments with hosts" do
    model = ChatDeploymentInfo.from_text("deploy hubot to production/fe1")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.application).to eql("fe1")
  end

  # rubocop:disable Metrics/LineLength
  it "handles deploying branches to environments with application" do
    model = ChatDeploymentInfo.from_text("deploy hubot/atmos/branch to production/fe1")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.application).to eql("fe1")
    expect(model.branch).to eql("atmos/branch")
  end

  it "handles deploying branches to environments with application plus yubikeys" do
    model = ChatDeploymentInfo.from_text("deploy hubot/atmos/branch to production/fe1 ccccccdlnncbtuevhdbctrccukdciveuclhbkvehbeve")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.application).to eql("fe1")
    expect(model.branch).to eql("atmos/branch")
    expect(model.second_factor).to eql("ccccccdlnncbtuevhdbctrccukdciveuclhbkvehbeve")
  end

  it "handles deploying branches to environments with hosts plus authenticator tokens" do
    model = ChatDeploymentInfo.from_text("deploy hubot/atmos/branch to production/fe1 123456")
    expect(model).to be_valid
    expect(model.environment).to eql("production")
    expect(model.application).to eql("fe1")
    expect(model.branch).to eql("atmos/branch")
    expect(model.second_factor).to eql("123456")
  end

  it "doesn't match on malformed yubikeys" do
    model = ChatDeploymentInfo.from_text("deploy hubot/atmos/branch to production/fe1 burgers")
    expect(model).to_not be_valid
  end

  it "doesn't match typos" do
    model = ChatDeploymentInfo.from_text("deploy hubot/atmos/branch tos taging")
    expect(model).to_not be_valid
  end
  # rubocop:enable Metrics/LineLength
end
