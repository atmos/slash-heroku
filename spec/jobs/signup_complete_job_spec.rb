require "rails_helper"

RSpec.describe SignupCompleteJob, type: :job do
  it "fills the user if the command has none" do
    command = Command.from_params(command_params_for("deploy slash-heroku"))
    user = create_atmos
    expect do
      SignupCompleteJob.perform_now(command_id: command.id, user_id: user.id)
    end.to change { command.reload.user_id }.from(nil).to(user.id)
  end
end
