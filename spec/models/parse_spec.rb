require "rails_helper"

RSpec.describe Parse::Releases do
  before do
    Timecop.freeze(Time.zone.local(2017, 1, 19))
  end

  after do
    Timecop.return
  end

  describe ".markdown" do
    it "returns a markdown of releases with heroku and github information" do
      releases =
        decoded_fixture_data("api.heroku.com/releases/slash-h-production/list")
      deploys =
        decoded_fixture_data(
          "api.github.com/repos/atmos/slash-heroku/deployments"
        )

      status = Parse::Release::STATUS_SUCCEEDED
      releases = Parse::Releases.new(releases, deploys, "heroku/reponame")
      releases_list = releases.markdown
      expect(releases_list.split("\n").size).to eql(10)

      # rubocop:disable LineLength
      branch_link = "<https://github.com/heroku/reponame/tree/more-debug-info|more-debug-info>"
      expect(releases_list)
        .to include("v149 - #{status} - Deploy e046008 - #{branch_link} - corey@heroku.com")
      expect(releases_list)
        .to include("v146 - #{status} - Update REDIS by heroku-redis - heroku-redis@addons.heroku.com")
      sha_link = "<https://github.com/heroku/reponame/tree/a2fa2f9|a2fa2f9>"
      expect(releases_list)
        .to include("v140 - #{status} - Deploy a2fa2f9 - #{sha_link} - corey@heroku.com - 5 days")
      # rubocop:enable LineLength
    end

    it "skips branch link if github deployments info doesn't exist" do
      releases =
        decoded_fixture_data("api.heroku.com/releases/slash-h-production/list")
      deploys = []

      status = Parse::Release::STATUS_SUCCEEDED
      releases = Parse::Releases.new(releases, deploys, "heroku/reponame")
      releases_list = releases.markdown
      expect(releases_list.split("\n").size).to eql(10)

      # rubocop:disable LineLength
      expect(releases_list)
        .to include("v149 - #{status} - Deploy e046008 - corey@heroku.com")
      expect(releases_list)
        .to include("v146 - #{status} - Update REDIS by heroku-redis - heroku-redis@addons.heroku.com")
      expect(releases_list)
        .to include("v140 - #{status} - Deploy a2fa2f9 - corey@heroku.com - 5 days")
      # rubocop:enable LineLength
    end
  end
end
