module HerokuCommands
  # Class for handling logging a user out
  class Logout < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "logout - Remove the user's auth information."
      ]
    end

    def run
      user.destroy
      @response = {
        attachments: [
          { text: "Successfully removed your user. :wink:" }
        ]
      }
    end
  end
end
