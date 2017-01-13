module HerokuCommands
  # Class for handling release info
  class Releases < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "releases -a APP - Display the last 10 releases for APP.",
        "releases:info RELEASE -a APP - View detailed information for a release"
      ]
    end

    def run
      @response = run_on_subtask
    end

    def release_info
      matches = command.command_text.match(/releases:\w+\s+(?:v)?([^\s]+)\s-a/)
      version = matches && matches[1]
      if version
        response = client.release_info_for(application, version)
        response_for_release(response)
      else
        response_for("release:info missing version, should be a number.")
      end
    end

    def releases_info
      if application
        response = client.releases_for(application)
        response_for_releases(response)
      else
        help_for_task
      end
    end

    def run_on_subtask
      case subtask
      when "info"
        release_info
      when "rollback"
        response_for("release:rollback is currently unimplemented.")
      else
        releases_info
      end
    rescue StandardError
      response_for("Unable to fetch recent releases for #{application}.")
    end

    def response_markdown_for(releases)
      releases.map do |release|
        "v#{release[:version]} - #{release[:description]} - " \
        "#{release[:user][:email]} - " \
          "#{time_ago_in_words(release[:created_at])}"
      end.join("\n")
    end

    def dashboard_markup(application)
      "<#{dashboard_link(application)}|#{application}>"
    end

    def dashboard_link(application)
      "https://dashboard.heroku.com/apps/#{application}"
    end

    def response_for_release(release)
      version     = release[:version]
      dashboard   = dashboard_markup(application)
      description = release[:description]
      {
        response_type: "in_channel",
        attachments: [
          {
            title: "#{dashboard} - v#{version} - #{description}",
            fallback: "Heroku release for #{application}:v#{version}",
            fields: [
              {
                title: "By",
                value: release[:user][:email],
                short: true
              },
              {
                title: "When",
                value: time_ago_in_words(release[:created_at]),
                short: true
              }
            ],
            color: COLOR
          }
        ]
      }
    end

    def response_for_releases(releases)
      {
        mrkdwn: true,
        response_type: "in_channel",
        attachments: [
          {
            color: COLOR,
            text: response_markdown_for(releases),
            title: "#{dashboard_markup(application)} - Recent releases",
            fallback: "Latest releases for Heroku application #{application}"
          }
        ]
      }
    end
  end
end
