module HerokuCommands
  # Class for handling authenticating a user
  class Login < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "login - Verify the user is authenticated with Heroku and GitHub."
      ]
    end

    def email
      user.heroku_user_information &&
        user.heroku_user_information["email"]
    end

    def run
      user_response
    end

    private

    def user_response
      {
        response_type: "ephemeral",
        text: response_main_text,
        attachments: [
          {
            color: response_color,
            mrkdwn_in: %w{text pretext fields},
            attachment_type: "default",
            fields: [heroku_response, github_response]
          }
        ]
      }
    end

    def response_main_text
      if onboarded?
        "You're all set"
      elsif onboarding?
        "Connect your GitHub account"
      else
        "Connect your Heroku account"
      end
    end

    def response_color
      if onboarded?
        "#36a64f"
      elsif onboarding?
        "#ffa807"
      else
        "#f00a1f"
      end
    end

    def heroku_response
      text = if heroku_configured?
               "You're #{user.heroku_email}."
             else
               "Please <#{command.heroku_auth_url}|sign in to Heroku>."
             end

      {
        title: "Heroku",
        value: text,
        short: true
      }
    end

    def github_response
      text = if github_configured?
               "You're #{github_link_for_slack}."
             else
               "Please <#{command.github_auth_url}|sign in to GitHub>."
             end

      {
        title: "GitHub",
        value: text,
        short: true
      }
    end

    def github_link_for_slack
      "<https://github.com/#{user.github_login}|#{user.github_login}>"
    end

    def onboarded?
      user && user.onboarded?
    end

    def onboarding?
      user && user.onboarding?
    end

    def heroku_configured?
      user && user.heroku_configured?
    end

    def github_configured?
      user && user.github_configured?
    end
  end
end
