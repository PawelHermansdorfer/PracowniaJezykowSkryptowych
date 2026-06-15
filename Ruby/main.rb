require 'selenium-webdriver'

wait   = Selenium::WebDriver::Wait.new(timeout: 15)
driver = Selenium::WebDriver.for :chrome

driver.navigate.to "https://www.amazon.pl"
sleep 1

print "Enter search phrase: "
# query = gets.chomp
query = "pokemon"

search_box = wait.until { driver.find_element(name: 'field-keywords') }
search_box.send_keys(query)

btn = driver.find_element(id: 'nav-search-submit-button')
btn.click

wait.until { driver.find_elements(css: 'div.s-main-slot div[data-component-type="s-search-result"]').any? }
items = driver.find_elements(css: 'div.s-main-slot div[data-component-type="s-search-result"]')

results = []

items.first(5).each do |item|
  title = item.find_elements(css: 'h2 span').first&.text

  price_whole      = item.find_elements(css: '.a-price-whole').first&.text
  price_fractional = item.find_elements(css: '.a-price-fraction').first&.text
  currency         = item.find_elements(css: '.a-price-symbol').first&.text

  link_el = item.find_elements(css: 'a.a-link-normal.s-no-outline').first
  link    = link_el&.attribute('href')

  results << {
    title: title,
    price: "#{price_whole}.#{price_fractional}#{currency}",
    url: link
  }
end

results.each do |item|
  next unless item[:url]
  driver.navigate.to(item[:url])

  delivery = wait.until do
    el = driver.find_elements(css: 'span[data-csa-c-content-id="DEXUnifiedCXPDM"]').first
    el if el && el.displayed?
  end
  delivery_info = {
    price: delivery&.attribute('data-csa-c-delivery-price'),
    time: delivery&.attribute('data-csa-c-delivery-time'),
    type: delivery&.attribute('data-csa-c-delivery-type'),
    condition: delivery&.attribute('data-csa-c-delivery-condition'),
    text: delivery&.text&.strip
  }

  item[:delivery] = delivery_info
end

results.each do |item|
  puts item[:title]
  puts item[:price]
  puts item[:delivery]
  puts "\n"
end
