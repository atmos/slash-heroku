module SlackHelpers
  def create_atmos
    slack = slack_omniauth_hash_for_atmos
    options = {
      slack_user_id: slack.info.user_id,
      slack_user_name: slack.info.name,
      slack_team_id: slack.info.team_id
    }
    User.create(options)
  end

  def command_params_for(text)
    {
      channel_id: "C99NNAY74",
      channel_name: "zf-promo",
      command: "/heroku",
      response_url: "https://hooks.slack.com/commands/T123YG08V/2459573/mPdDq",
      team_id: "T123YG08V",
      team_domain: "zf",
      text: text
    }
  end

  def command_for(text)
    user = create_atmos
    user.heroku_token         = SecureRandom.hex(24)
    user.heroku_refresh_token = SecureRandom.hex(24)
    user.heroku_expires_at    = 6.hours.from_now
    user.save
    user.create_command_for(command_params_for(text))
  end
end
