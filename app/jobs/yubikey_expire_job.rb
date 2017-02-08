# Job to handle kicking off a Deployment request
class YubikeyExpireJob < ApplicationJob
  queue_as :default
  YUBIKEY_REGEX = /([cbdefghijklnrtuv]{32,}|[jxe\.uidchtnbpygk]{32,})/i

  # rubocop:disable Metrics/AbcSize
  def perform(*args)
    command_id = args.first.fetch(:command_id)

    command = Command.find(command_id)
    matches = command.command_text.match(YUBIKEY_REGEX)
    if matches
      response = client.post do |request|
        request.url "/"
        request.body = "key=#{matches[1]}"
        request.headers["Content-Type"] = "application/x-www-form-urlencoded"
      end
      Librato.increment "yubikey.expire.total"
      case response.body
      when "token was already used"
        Librato.increment "yubikey.expire.used"
      when "token successfully invalidated"
        Librato.increment "yubikey.expire.unused"
      else
        Rails.logger.info "Yubikey expire: #{response.body}"
      end
    end
  rescue StandardError => e
    Rails.logger.info "Yubiexpire went wonky: '#{e.inspect}'"
  end

  def client
    @client ||= Faraday.new(url: "https://#{ENV['YUBIEXPIRE_HOSTNAME']}") do |c|
      c.use :instrumentation
      c.use ZipkinTracer::FaradayHandler, "api.yubico.com"
      c.adapter Faraday.default_adapter
    end
  end
end
