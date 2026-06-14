require 'nokogiri'
require 'httparty'

url = 'http://books.toscrape.com/'

response = HTTParty.get(url)
document = Nokogiri::HTML(response.body)

books = document.css('.product_pod')

books.each do |book|
  title = book.css('h3 a').attribute('title').value
  price = book.css('.price_color').text
  
  puts "Title: #{title}"
  puts "price:  #{price}"
  puts "\n"
end
