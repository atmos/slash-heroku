module HerokuCommands
  # Class for handling logout and identity information
  class Auth < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "auth:login  - Display the email of the authenticated user.",
        "auth:logout - Delete your user and all commands you've run."
      ]
    end

    def email
      user.heroku_user_information &&
        user.heroku_user_information["email"]
    end

    def run
      @response = case subtask
                  when "logout"
                    user.destroy
                    {
                      attachments: [
                        { text: "Successfully removed your user. :wink:" }
                      ]
                    }
                  when "whoami"
                    {
                      attachments: [
                        { text: "You're authenticated as #{email} on Heroku." }
                      ]
                    }
                  else
                    help_for_task
                  end
    end
  end
end
