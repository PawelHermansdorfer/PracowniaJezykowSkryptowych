require "httparty"
require "nokogiri"

def list_amazon_items(query)
  url = "https://www.amazon.com/s?k=#{query}"
  response = HTTParty.get(url, headers: { "User-Agent" => "Mozilla/5.0" })
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

    items << {
      title: title,
      price: price || 'nil'
    }
  end

  items
end

items = list_amazon_items("pokemon")

items.each_with_index do |item|
  puts "#{item[:title]}"
  puts "#{item[:price]}"
  puts "\n"
end
