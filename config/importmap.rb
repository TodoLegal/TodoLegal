# Pin npm packages by running ./bin/importmap

pin "application"
# pin "@rails/ujs@7", to: "https://ga.jspm.io/npm:@rails/ujs@7.1.2/lib/assets/compiled/rails-ujs.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "trix"

pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"
# pin_all_from 'app/javascript/src', under: 'src'
pin "javascript/src/clear_sarchInput", preload: false
pin "javascript/src/form_validator", preload: false
pin "javasript/src/help_card", preload: false
pin "javascript/src/hide_card", preload: false
pin "javascript/src/law_subbar_actions", preload: false
pin "javascript/src/preferences_validator", preload: false
pin "javascript/src/stripe_integration", preload: false
pin "javascript/src/trim_articles_for_preview", preload: false

pin "lodash.debounce" # @4.0.8
