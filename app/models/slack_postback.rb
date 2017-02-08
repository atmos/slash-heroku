# Sends a Slack message to a given Slack url
class SlackPostback
  attr_reader :message, :url

  def self.for(message, url)
    new(message, url).postback_message
  end

  def initialize(message, url)
    @message = message
    @url = url
  end

  def postback_message
    response = client.post do |request|
      request.url callback_uri.path
      request.body = message.to_json
      request.headers["Content-Type"] = "application/json"
    end

    Rails.logger.info action: "command#postback_message", body: response.body
  rescue StandardError => e
    Rails.logger.info "Unable to post back to slack: '#{e.inspect}'"
  end

  def callback_uri
    @callback_uri ||= Addressable::URI.parse(url)
  end

  def client
    @client ||= Faraday.new(url: "https://hooks.slack.com") do |c|
      c.use :instrumentation
      c.use ZipkinTracer::FaradayHandler, "hooks.slack.com"
      c.adapter Faraday.default_adapter
    end
  end
end
