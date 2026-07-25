require_relative "base_fetcher"

module Fetchers
  class ZennFetcher < BaseFetcher
    FEED_URL = "https://zenn.dev/y_uuu/feed"

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
      }
    end
  end
end
