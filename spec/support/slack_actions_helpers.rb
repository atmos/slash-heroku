module SlackActionsHelpers
  def action_params_for(callback_id = "environment", value = "staging")
    {
      actions: [
        {
          name: value,
          value: value
        }
      ],
      callback_id: callback_id,
      team: {
        id: "T0QQTP89F",
        domain: "heroku"
      },
      channel: {
        id: "C0QQS2U6B",
        name: "general"
      },
      user: {
        id: "U0QQTEQ5C",
        name: "yannick"
      },
      action_ts: "1480454458.026997",
      message_ts: "1480454212.000005",
      token: "some-secret-slack-token",
      response_url: "https://hooks.slack.com/actions/some-path"
    }
  end
end
