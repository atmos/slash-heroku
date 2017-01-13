# Class for encapsulating a chat deployment request
class Deployment
  include ActiveModel::Model

  attr_writer :environment
  attr_accessor :task, :application, :branch, :forced, :hosts, :second_factor

  def self.valid_slug
    "([-_\.0-9a-z]+)"
  end

  # rubocop:disable Metrics/LineLength
  def self.pattern_parts
    [
      "(deploy(?:\:[^\s]+)?)",                        # / prefix
      "(!)?\s+",                                      # Whether or not it was a forced deployment
      valid_slug.to_s,                                # application name, from apps.json
      "(?:\/([^\s]+))?",                              # Branch or sha to deploy
      "(?:\s+(?:to|in|on)\s+",                        # http://i.imgur.com/3KqMoRi.gif
      valid_slug.to_s,                                # Environment to release to
      "(?:\/([^\s]+))?)?\s*",                         # Host filter to try
      "(?:([cbdefghijklnrtuv]{32,64}|\\d{6})?\s*)?$"  # Optional Yubikey
    ]
  end
  # rubocop:enable Metrics/LineLength

  def self.from_text(text)
    args = text_to_deployment_args(text)
    Deployment.new(args)
  end

  def self.text_to_deployment_args(text)
    deploy_pattern = Regexp.new(pattern_parts.join(""))
    matches = deploy_pattern.match(text)
    return {} unless matches
    {
      task:          matches[1],
      forced:        matches[2] == "!",
      application:   matches[3],
      branch:        matches[4] || "master",
      environment:   matches[5],
      hosts:         matches[6],
      second_factor: matches[7]
    }
  end

  def initialize(args = {})
    super
    @forced ||= false
    @branch ||= "master"
  end

  def forced?
    forced
  end

  def valid?
    application.present?
  end

  def environment
    case @environment
    when "prod", "prd"
      "production"
    when "stg"
      "staging"
    else
      @environment
    end
  end
end
