# Namespace for containing HerokuCommands
module HerokuCommands
  # Top-level class for implementing Heroku commands
  class HerokuCommand
    include ActionView::Helpers::DateHelper

    COLOR = "#6567a5".freeze
    UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    attr_reader :command
    delegate :application, :subtask, :task, :user, to: :@command

    def initialize(command)
      @command = command
    end

    def run
      # Overridden in each subclass
    end

    def self.help_documentation
      []
    end

    def help_for_task
      {
        response_type: "in_channel",
        attachments: [
          {
            text: self.class.help_documentation.join("\n"),
            pretext: "Run /h help releases for task specific help",
            fallback: "Help commands from the heroku integration",
            title: "Available heroku #{task} commands:",
            title_link: "https://github.com/atmos/slash-heroku#slashheroku-"
          }
        ]
      }
    end

    def error_response_for(text)
      { response_type: "in_channel",
        attachments: [{ text: text, color: "#f00" }] }
    end

    def error_response_for_escobar_two_factor(error)
      {
        attachments: [
          { text: "<#{error.dashboard_url}|Unlock " \
                  "#{error.build_request.app.name}>" }
        ]
      }
    end

    def error_response_for_escobar_known_exception(error)
      {
        response_type: "in_channel",
        attachments: [
          { text: error.message }
        ]
      }
    end

    def error_response_for_escobar(error)
      case error.message
      when /Commit status checks failed/i
        error_response_for_escobar_known_exception(error)
      when /requires second factor/i
        error_response_for_escobar_two_factor(error)
      when /Unable to create heroku build/i
        error_response_for_escobar_known_exception(error)
      else
        Raven.capture_exception(error)
        Rails.logger.info source: :escobar, error: error.message
        {}
      end
    end

    def response_for(text)
      { text: text, response_type: "in_channel" }
    end
  end
end
