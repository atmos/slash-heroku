# rubocop:disable Metrics/LineLength
module WebmockHelpers
  def default_json_headers
    { "Content-Type" => "application/json" }
  end

  def stub_json_request(method, url, response_body, status = 200)
    stub_request(method, url)
      .to_return(status: status, body: response_body, headers: default_json_headers)
  end

  def stub_heroku_request(method, path, response_body, status = 200)
    base_url = "https://api.heroku.com"
    stub_request(method, base_url + path)
      .to_return(status: status, body: response_body, headers: default_json_headers)
  end

  def stub_github_request(method, path, response_body, status = 200)
    base_url = "https://api.github.com"
    stub_request(method, base_url + path)
      .to_return(status: status, body: response_body, headers: default_json_headers)
  end

  def stub_slack_request(body)
    stub_request(:post, "https://hooks.slack.com/commands/T123YG08V/2459573/mPdDq")
      .with(body:    body,
            headers: default_json_headers)
      .to_return(status: 200, body: "", headers: {})
  end
end
# rubocop:enable Metrics/LineLength
