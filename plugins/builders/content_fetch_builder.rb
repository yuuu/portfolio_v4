require_relative "../../lib/fetchers/qiita_fetcher"
require_relative "../../lib/fetchers/zenn_fetcher"
require_relative "../../lib/fetchers/speaker_deck_fetcher"
require_relative "../../lib/fetchers/fusic_fetcher"
require_relative "../../lib/fetchers/hatena_fetcher"
require_relative "../../lib/fetchers/extra_articles_fetcher"

# Populates the `articles` and `slides` collections at build time from
# external RSS/API sources, replacing the old DynamoDB-backed pipeline.
class Builders::ContentFetchBuilder < SiteBuilder
  ARTICLE_SOURCES = [
    Fetchers::QiitaFetcher,
    Fetchers::ZennFetcher,
    Fetchers::FusicFetcher,
    Fetchers::HatenaFetcher,
    Fetchers::ExtraArticlesFetcher,
  ].freeze

  SLIDE_SOURCES = [
    Fetchers::SpeakerDeckFetcher,
  ].freeze

  def build
    cache = Bridgetown::Cache.new("content-fetch")

    ARTICLE_SOURCES.each { |klass| ingest(klass, :articles, cache) }
    SLIDE_SOURCES.each { |klass| ingest(klass, :slides, cache) }
  end

  private

  # A single source failing entirely (network down, feed format changed)
  # must not prevent the other sources from being ingested and the site
  # from being built.
  def ingest(fetcher_class, collection, cache)
    fetcher_class.new(cache:).fetch.each do |item|
      add_resource collection, "#{item[:source]}-#{item[:id]}.html" do
        title item[:title]
        link item[:link]
        image item[:image_url]
        published_at item[:published_at]
        categories item[:categories] || []
        source item[:source]
        content item[:body]
      end
    end
  rescue StandardError => e
    Bridgetown.logger.error("ContentFetchBuilder:", "#{fetcher_class} failed entirely: #{e.message}")
  end
end
