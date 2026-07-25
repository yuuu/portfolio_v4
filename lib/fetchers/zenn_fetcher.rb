require_relative "base_fetcher"

module Fetchers
  class ZennFetcher < BaseFetcher
    FEED_URL = "https://zenn.dev/y_uuu/feed"
    # Zenn's RSS has no like count, so this unofficial API is used
    # alongside it just to look up liked_count per article.
    LIKES_API_ENDPOINT = "https://zenn.dev/api/articles?username=y_uuu&count=100"

    private

    def fetch_raw_items
      res = http.get(FEED_URL)
      RSS::Parser.parse(res.body, true).items
    end

    def normalize(item)
      {
        id: make_id(item.link),
        title: item.title,
        body: truncate_body(item.description),
        link: item.link,
        published_at: item.date,
        image_url: scrape_og_image(item.link),
        source: "zenn",
        likes_count: liked_count_for(item.link),
        hatena_bookmark_count: fetch_hatena_bookmark_count(item.link),
      }
    end

    def liked_count_for(link)
      likes_by_path.each do |path, count|
        return count if link.end_with?(path)
      end
      nil
    end

    def likes_by_path
      @likes_by_path ||= begin
        res = http.get(LIKES_API_ENDPOINT)
        JSON.parse(res.body)["articles"].to_h { |a| [a["path"], a["liked_count"]] }
      rescue Faraday::Error, JSON::ParserError => e
        @logger.warn("Fetchers::Zenn", "failed to fetch likes API: #{e.message}")
        {}
      end
    end
  end
end
