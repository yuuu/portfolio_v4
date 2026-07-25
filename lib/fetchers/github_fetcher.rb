require_relative "base_fetcher"

module Fetchers
  # Unlike the RSS-based fetchers, this combines two GitHub sources into one
  # ranked list: pinned repos (scraped from the profile page — GitHub's REST
  # API has no public "pinned repos" endpoint, and this can include repos
  # the user doesn't own, like OSS contributions) and all owned public repos
  # with at least one star. The two sets are merged (pinned repos win on
  # overlap) and sorted by star count.
  class GithubFetcher < BaseFetcher
    USERNAME = "yuuu"
    PROFILE_URL = "https://github.com/#{USERNAME}"
    API_BASE = "https://api.github.com"

    def fetch
      repos = {}

      pinned_repos.each { |r| repos[r[:full_name]] = r }
      starred_owned_repos.each { |r| repos[r[:full_name]] ||= r }

      repos.values.sort_by { |r| -r[:stars] }
    rescue StandardError => e
      @logger.error("Fetchers::Github", "fetch failed entirely: #{e.message}")
      []
    end

    private

    def pinned_repos
      doc = Nokogiri::HTML(http.get(PROFILE_URL).body)
      doc.css("li.js-pinned-item-list-item").filter_map do |item|
        link = item.at("a.Link")
        next unless link

        full_name = link["href"].delete_prefix("/")
        {
          full_name: full_name,
          description: item.at("p.pinned-item-desc")&.text&.strip,
          language: item.at("span[itemprop='programmingLanguage']")&.text,
          stars: item.at("a[href$='stargazers']")&.text&.strip.to_i,
          url: "https://github.com/#{full_name}",
        }
      end
    rescue Faraday::Error => e
      @logger.warn("Fetchers::Github", "failed to fetch pinned repos: #{e.message}")
      []
    end

    def starred_owned_repos
      raw_repos = []
      page = 1

      loop do
        res = http.get("#{API_BASE}/users/#{USERNAME}/repos?type=owner&per_page=100&page=#{page}")
        break unless res.status == 200

        batch = JSON.parse(res.body)
        break if batch.empty?

        raw_repos.concat(batch)
        break if batch.size < 100

        page += 1
      end

      raw_repos.reject { |r| r["fork"] || r["stargazers_count"].to_i < 1 }.map do |r|
        {
          full_name: r["full_name"],
          description: r["description"],
          language: r["language"],
          stars: r["stargazers_count"],
          url: r["html_url"],
        }
      end
    rescue Faraday::Error => e
      @logger.warn("Fetchers::Github", "failed to fetch owned repos: #{e.message}")
      []
    end
  end
end
