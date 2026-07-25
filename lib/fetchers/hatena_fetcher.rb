require_relative "base_fetcher"

module Fetchers
  # ylgbk.hatenablog.com is a personal blog, so unlike FusicFetcher every
  # entry is embedded without an author filter. Hatena's Atom feed paginates
  # via ?page=N (page=1 == no param) and returns zero entries past the last
  # page, so we walk pages until empty to reach every post ever published.
  class HatenaFetcher < BaseFetcher
    BASE_FEED_URL = "https://ylgbk.hatenablog.com/feed"
    MAX_PAGES = 50

    private

    def fetch_raw_items
      items = []

      (1..MAX_PAGES).each do |page|
        res = http.get("#{BASE_FEED_URL}?page=#{page}")
        break unless res.status == 200

        page_items = RSS::Parser.parse(res.body, true).items
        break if page_items.empty?

        items.concat(page_items)
      end

      items
    end

    def normalize(item)
      {
        id: make_id(item.link.href),
        title: item.title.content,
        body: truncate_body(item.summary&.content),
        link: item.link.href,
        published_at: item.published&.content || item.updated.content,
        image_url: scrape_og_image(item.link.href),
        source: "hatena",
        categories: item.categories.map { |c| c.term },
        hatena_bookmark_count: fetch_hatena_bookmark_count(item.link.href),
      }
    end
  end
end
