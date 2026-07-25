require_relative "base_fetcher"

module Fetchers
  class QiitaFetcher < BaseFetcher
    ENDPOINT = "https://qiita.com/api/v2/users/Y_uuu/items?per_page=100"

    private

    def fetch_raw_items
      res = http.get(ENDPOINT)
      JSON.parse(res.body)
    end

    def normalize(raw)
      {
        id: make_id(raw["url"]),
        title: raw["title"],
        body: truncate_body(raw["body"]),
        link: raw["url"],
        published_at: Time.parse(raw["created_at"]),
        image_url: scrape_og_image(raw["url"]),
        source: "qiita",
      }
    end
  end
end
