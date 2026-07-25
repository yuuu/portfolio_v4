require "faraday"
require "faraday/retry"
require "faraday/follow_redirects"
require "nokogiri"
require "sanitize"
require "digest"
require "json"
require "rss"
require "time"
require "cgi"

module Fetchers
  class BaseFetcher
    OGP_OPEN_TIMEOUT = 3
    OGP_TIMEOUT = 5

    def initialize(cache:, logger: Bridgetown.logger)
      @cache = cache
      @logger = logger
    end

    # Subclasses implement fetch_raw_items and normalize(raw_item).
    # normalize must return a Hash with keys:
    #   :id, :title, :body, :link, :published_at, :image_url, :source
    # and may return nil to skip an item.
    def fetch
      fetch_raw_items.filter_map do |raw|
        begin
          normalize(raw)
        rescue StandardError => e
          @logger.warn("Fetchers::#{self.class.name}", "skip item due to error: #{e.message}")
          nil
        end
      end
    rescue StandardError => e
      @logger.error("Fetchers::#{self.class.name}", "fetch failed entirely: #{e.message}")
      []
    end

    private

    def http
      @http ||= Faraday.new do |f|
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2
        f.response :follow_redirects
        f.options.timeout = 8
        f.options.open_timeout = 3
        f.adapter Faraday.default_adapter
      end
    end

    # Scrapes the og:image meta tag from a page, caching the result per URL
    # across builds so repeat builds don't re-scrape unchanged articles.
    def scrape_og_image(url)
      @cache.getset("og_image:#{url}") do
        res = Faraday.new do |f|
          f.response :follow_redirects
          f.options.timeout = OGP_TIMEOUT
          f.options.open_timeout = OGP_OPEN_TIMEOUT
        end.get(url)
        doc = Nokogiri::HTML(res.body)
        doc.at('meta[property="og:image"]')&.attr("content")
      end
    rescue Faraday::Error, Timeout::Error => e
      @logger.warn("Fetchers::OGP", "failed to scrape #{url}: #{e.message}")
      nil
    end

    # Hatena Bookmark's public jsonlite endpoint returns the bookmarking
    # user count for any URL, regardless of source site. Cached per URL like
    # scrape_og_image, since it's requested for every article/slide.
    def fetch_hatena_bookmark_count(url)
      @cache.getset("hatena_bookmark_count:#{url}") do
        res = http.get("https://b.hatena.ne.jp/entry/jsonlite/?url=#{CGI.escape(url)}")
        data = JSON.parse(res.body)
        data.is_a?(Hash) ? data["count"].to_i : 0
      end
    rescue Faraday::Error, JSON::ParserError => e
      @logger.warn("Fetchers::HatenaBookmark", "failed to fetch count for #{url}: #{e.message}")
      0
    end

    def make_id(url)
      Digest::MD5.hexdigest(url)
    end

    def truncate_body(text, length = 100)
      stripped = Sanitize.fragment(text.to_s).strip
      stripped.length > length ? "#{stripped[0...length]}..." : stripped
    end
  end
end
