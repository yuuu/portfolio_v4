require_relative "base_fetcher"

module Fetchers
  # sizu.me (しずかなインターネット) exposes a plain RSS 2.0 feed with no
  # working pagination (a ?page= param is accepted but always returns the
  # same items), but the account only has a couple dozen posts, so the feed
  # already covers the full history.
  class SizumeFetcher < BaseFetcher
    FEED_URL = "https://sizu.me/y_uuu/rss"

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
        image_url: item.enclosure&.url,
        source: "sizu.me",
        hatena_bookmark_count: fetch_hatena_bookmark_count(item.link),
      }
    end
  end
end
