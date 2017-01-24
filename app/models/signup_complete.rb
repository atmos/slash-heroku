# Notifies the user that they're done signing up
class SignupComplete
  attr_reader :slack_user_id, :postback_url

  def self.notify(slack_user_id, postback_url)
    new(slack_user_id, postback_url).notify_user_of_success
  end

  def initialize(slack_user_id, postback_url)
    @slack_user_id = slack_user_id
    @postback_url = postback_url
  end

  def notify_user_of_success
    return unless user
    SlackPostback.for(message, postback_url)
  end

  def user
    User.find_by(slack_user_id: slack_user_id)
  end

  def name
    "<@#{user.slack_user_id}|#{user.slack_user_name}>"
  end

  def message
    text_response("#{name} you're all set. :tada:")
  end

  def text_response(text)
    { text: text, response_type: "in_channel" }
  end
end
