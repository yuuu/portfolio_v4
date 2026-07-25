require_relative "base_fetcher"

module Fetchers
  # SpeakerDeck's Atom feed paginates via ?page=N and returns zero entries
  # past the last page, so we walk pages until empty to reach every talk
  # ever uploaded (not just the most recent ones).
  class SpeakerDeckFetcher < BaseFetcher
    BASE_FEED_URL = "https://speakerdeck.com/yuuu.atom"
    MAX_PAGES = 50

    private

    def fetch_raw_items
      entries = []

      (1..MAX_PAGES).each do |page|
        res = http.get("#{BASE_FEED_URL}?page=#{page}")
        break unless res.status == 200

        # do_validate: false — pages beyond the first omit the feed-level
        # <updated> tag that strict Atom validation requires.
        page_entries = RSS::Parser.parse(res.body, false).entries
        break if page_entries.empty?

        entries.concat(page_entries)
      end

      entries
    end

    def normalize(entry)
      {
        id: make_id(entry.link.href),
        title: entry.title.content,
        body: truncate_body(entry.content.content),
        link: entry.link.href,
        published_at: entry.published.content,
        image_url: scrape_og_image(entry.link.href),
        source: "speakerdeck",
      }
    end
  end
end
