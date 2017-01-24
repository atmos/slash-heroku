# Generates command body and posts it to slack
class ExecuteCommand
  attr_reader :command

  def self.for(command)
    new(command).run
  end

  def initialize(command)
    @command = command
  end

  def run
    handler.run
    SlackPostback.for(handler.response, command.response_url)
  end

  def handler
    @handler ||= case command.task
                 when "deploy"
                   HerokuCommands::Deploy.new(command)
                 when "login"
                   HerokuCommands::Login.new(command)
                 when "logout"
                   HerokuCommands::Logout.new(command)
                 when "pipeline", "pipelines"
                   HerokuCommands::Pipelines.new(command)
                 when "releases"
                   HerokuCommands::Releases.new(command)
                 else # when "help"
                   HerokuCommands::Help.new(command)
                 end
  end
end
