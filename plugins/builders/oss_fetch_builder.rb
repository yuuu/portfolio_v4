require_relative "../../lib/fetchers/github_fetcher"

# Populates site.data["oss"] with the user's pinned + starred public GitHub
# repos at build time, replacing the old static apps.yml Data File.
#
# Uses add_data (post_read hook) rather than writing to site.data directly
# in `build` (pre_read hook): the Data Files reader runs after pre_read and
# would otherwise clobber a direct assignment.
class Builders::OssFetchBuilder < SiteBuilder
  def build
    add_data("oss") do
      cache = Bridgetown::Cache.new("oss-fetch")
      Fetchers::GithubFetcher.new(cache:).fetch
    rescue StandardError => e
      Bridgetown.logger.error("OssFetchBuilder:", "failed entirely: #{e.message}")
      []
    end
  end
end
