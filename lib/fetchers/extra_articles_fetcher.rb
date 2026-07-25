require_relative "base_fetcher"
require "uri"

module Fetchers
  # A hand-picked list of articles from sites not otherwise syndicated
  # (Think IT, FJORD BOOT CAMP), added as a one-off request rather than a
  # general feed integration. Metadata (title/date/image/summary) is still
  # scraped from each page at build time so it stays accurate if the source
  # pages change, instead of being hardcoded here.
  class ExtraArticlesFetcher < BaseFetcher
    URLS = [
      "https://thinkit.co.jp/article/17312",
      "https://thinkit.co.jp/article/17360",
      "https://thinkit.co.jp/article/17384",
      "https://bootcamp.fjord.jp/articles/78",
      "https://bootcamp.fjord.jp/articles/64",
      "https://thinkit.co.jp/story/2013/04/11/4043",
      "https://thinkit.co.jp/story/2013/04/18/4046",
    ].freeze

    private

    def fetch_raw_items
      URLS
    end

    def normalize(url)
      doc = Nokogiri::HTML(http.get(url).body)

      {
        id: make_id(url),
        title: doc.at('meta[property="og:title"]')&.attr("content"),
        body: truncate_body(doc.at('meta[property="og:description"]')&.attr("content")),
        link: url,
        published_at: parse_published_at(doc),
        image_url: doc.at('meta[property="og:image"]')&.attr("content"),
        source: source_label(url),
        hatena_bookmark_count: fetch_hatena_bookmark_count(url),
      }
    end

    def source_label(url)
      URI(url).host.include?("fjord") ? "fjord" : "thinkit"
    end

    # thinkit.co.jp exposes article:published_time; bootcamp.fjord.jp only
    # renders a Japanese-formatted date string in a .published-at element.
    def parse_published_at(doc)
      meta = doc.at('meta[property="article:published_time"]')
      return Time.parse(meta["content"]) if meta

      text = doc.at(".article__published-at")&.text
      return nil unless text

      match = text.match(/(\d{4})年(\d{2})月(\d{2})日.*?(\d{2}):(\d{2})/)
      return nil unless match

      Time.new(*match.captures.map(&:to_i))
    end
  end
end
