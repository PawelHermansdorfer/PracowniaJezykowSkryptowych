require "nokogiri"
require "httparty"


HEADERS = {
  "User-Agent" => "Mozilla/5.0",
  "Accept-Language" => "en-US,en;q=0.9"
}


def captcha_page?(html)
  html.include?("bm-verify") || html.include?("interstitial") || html.include?("captcha") || html.include?("/sec/verify")
end


def get_details(asin)
  url = "https://www.amazon.com/dp/#{asin}"
  response = HTTParty.get(url, headers: HEADERS)
  doc = Nokogiri::HTML(response.body)

  details = {}
  doc.css("ul.a-unordered-list.a-nostyle.a-vertical.detail-bullet-list li").each do |li|
    label = li.at("span.a-text-bold")&.text&.strip
    value = li.search("span").map(&:text).last&.strip

    next unless label && value

    label = label.gsub("‏", "").gsub(":", "").strip
    details[label] = value
  end

  rating = doc.at("span.a-icon-alt")&.text
  reviews = doc.at("#acrCustomerReviewText")&.text
  details["Customer Rating"] = rating if rating
  details["Customer Reviews"] = reviews if reviews

  details
end


def list_amazon_items(query)
  url = "https://www.amazon.com/s?k=#{query}"
  response = HTTParty.get(url, headers: HEADERS)
  if captcha_page?(response.body)
    puts "CAPTCHA required"
    exit
  end

  doc = Nokogiri::HTML(response.body)

  items = []
  doc.css("div.s-result-item[data-asin]").each do |item|
    asin = item["data-asin"]
    next if asin.nil? || asin.empty?

    title_node = item.at("h2 span")
    next unless title_node

    title = title_node.text.strip
    price_span = item.at("span.a-price span.a-offscreen")
    price = price_span ? price_span.text.strip : nil

    details = get_details(asin)

    puts "#{title}"
    puts "#{price}"
    details.each do |a, b|
      puts "#{a}: #{b}"
    end
    puts "\n"

    sleep 1
  end
end


print "Enter search phrase: "
phrase = STDIN.gets&.chomp
list_amazon_items(phrase)
