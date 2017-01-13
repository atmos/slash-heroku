module HerokuCommands
  # Class for handling logout and identity information
  class Help < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        HerokuCommands::Auth.help_documentation,
        HerokuCommands::Deploy.help_documentation,
        HerokuCommands::Pipelines.help_documentation,
        HerokuCommands::Releases.help_documentation
      ].flatten
    end

    def run
      @response = help_for_task
    end
  end
end
