require_relative "base_fetcher"

module Fetchers
  # tech.fusic.co.jp is a multi-author blog with no author field in its RSS
  # feed, and that feed only carries recent posts. To reach every post ever
  # published we instead walk the sitemap (which lists all /posts/ URLs back
  # to 2018) and scrape each article's author byline (rendered next to an
  # `alt="Author"` avatar image), keeping only this site owner's own posts.
  class FusicFetcher < BaseFetcher
    SITEMAP_URL = "https://tech.fusic.co.jp/sitemap-0.xml"
    AUTHOR_NAME = "Yuhei Okazaki"
    PUBLISHED_DATE_PATTERN = %r{\A\d{4}/\d{2}/\d{2}\z}

    private

    def fetch_raw_items
      res = http.get(SITEMAP_URL)
      doc = Nokogiri::XML(res.body)
      doc.remove_namespaces!
      doc.css("url > loc").map(&:text).select { |url| url.include?("/posts/") }
    end

    # One cached HTML fetch per article covers author check, title, date,
    # body, and OGP image — versus separate requests per field — since every
    # sitemap URL (418+ as of writing) needs at least the author lookup.
    def normalize(url)
      doc = fetch_article_doc(url)
      return nil unless doc

      author_el = doc.at('img[alt="Author"]')
      return nil unless author_el && author_el.parent.text.include?(AUTHOR_NAME)

      {
        id: make_id(url),
        title: doc.at("title")&.text,
        body: truncate_body(doc.at("main")&.text),
        link: url,
        published_at: parse_published_at(doc),
        image_url: doc.at('meta[property="og:image"]')&.attr("content"),
        source: "fusic",
        hatena_bookmark_count: fetch_hatena_bookmark_count(url),
      }
    end

    def fetch_article_doc(url)
      html = @cache.getset("fusic_html:#{url}") { http.get(url).body }
      Nokogiri::HTML(html)
    rescue Faraday::Error => e
      @logger.warn("Fetchers::Fusic", "failed to fetch #{url}: #{e.message}")
      nil
    end

    def parse_published_at(doc)
      text = doc.css("p").map(&:text).find { |t| t.strip.match?(PUBLISHED_DATE_PATTERN) }
      text ? Time.strptime(text.strip, "%Y/%m/%d") : nil
    end
  end
end
