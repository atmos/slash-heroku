module Parse
  # Parses information about Heroku releases and GitHub deployment info
  class Releases
    attr_reader :releases, :deploys, :github_repository

    def initialize(releases, deploys, github_repository)
      @releases = releases
      @deploys = deploys
      @github_repository = github_repository
    end

    def markdown
      releases.map do |release|
        refs = GitHubRefs.new(deploys)
        Release.new(release, refs, github_repository).row_text
      end.join("\n")
    end
  end

  # Generates a hash of shas with corresponding refs
  class GitHubRefs
    attr_reader :deploy_list

    def initialize(deploy_list)
      @deploy_list = deploy_list
    end

    def by_sha(sha)
      sha_and_ref_hash[sha]
    end

    def sha_and_ref_hash
      @sha_and_ref_hash ||=
        deploy_list.each_with_object({}) do |deploy, hash|
          sha = deploy["sha"]
          shortened_sha = sha[0..6]
          ref = deploy["ref"]
          ref = shortened_sha if sha == ref
          hash[shortened_sha] = ref
        end
    end
  end

  # Returns information about a single release
  class Release
    STATUS_FAILED = ":icon_failure:".freeze
    STATUS_SUCCEEDED = ":icon_success:".freeze

    include ActionView::Helpers::DateHelper
    attr_reader :release_info, :github_refs, :name_with_owner

    def initialize(release_info, github_refs, name_with_owner)
      @release_info = release_info
      @github_refs = github_refs
      @name_with_owner = name_with_owner
    end

    def row_text
      "v#{version} - #{status} - #{description} - " \
        "#{optional_branch_link}" \
          "#{email} - " \
            "#{created_at}"
    end

    def optional_branch_link
      return unless ref
      "<https://github.com/#{name_with_owner}/tree/#{ref}|#{ref}> - "
    end

    def version
      release_info["version"]
    end

    def email
      release_info["user"]["email"]
    end

    def status
      release_info["status"] == "failed" ? STATUS_FAILED : STATUS_SUCCEEDED
    end

    def created_at
      time_ago_in_words(release_info["created_at"])
    end

    def sha
      sha = description.gsub("Deploy ", "")
      sha =~ /\A\h{7,40}\z/ ? sha[0..6] : nil
    end

    def description
      release_info["description"]
    end

    def ref
      return unless sha
      github_refs.by_sha(sha)
    end
  end
end
