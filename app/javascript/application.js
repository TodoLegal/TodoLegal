// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// require("@rails/ujs").start()
// require("@rails/activestorage").start()
// import "@rails/ujs@7"
import "@rails/activestorage"
// import "channels"
import "@hotwired/turbo-rails"
import "controllers"

// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { application } from "controllers/application"
