// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// require("@rails/ujs").start()
// require("@rails/activestorage").start()
// import "@rails/ujs"
import "@rails/activestorage"
// import "channels"
import "@hotwired/turbo-rails"
import "controllers"
import "src/clear_searchInput"
import "src/form_validator"
import "src/help_card"

console.log("application.js is loaded");
// console.log(helpCard);