require 'selenium-webdriver'

wait   = Selenium::WebDriver::Wait.new(timeout: 15)
driver = Selenium::WebDriver.for :chrome

driver.navigate.to "https://www.amazon.com"
sleep 1

print "Enter search phrase: "
query = gets.chomp

search_box = wait.until { driver.find_element(name: 'field-keywords') }
search_box.send_keys(query)

btn = driver.find_element(id: 'nav-search-submit-button')
btn.click

wait.until { driver.find_elements(css: 'div.s-main-slot div[data-component-type="s-search-result"]').any? }
items = driver.find_elements(css: 'div.s-main-slot div[data-component-type="s-search-result"]')

items.first(20).each do |item|
  title            = item.find_elements(css: 'h2 span').first&.text
  price_whole      = item.find_elements(css: '.a-price-whole').first&.text
  price_fractional = item.find_elements(css: '.a-price-fraction').first&.text
  currancy         = item.find_elements(css: '.a-price-symbol').first&.text
  # link = item.find_elements(css: 'a.a-link-normal.s-no-outline').first
  # link = link&.attribute('href')

  puts title
  puts "#{price_whole}.#{price_fractional}#{currancy}"
  puts "\n"
end
