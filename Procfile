web: bundle exec puma -C config/puma.rb
worker: /usr/bin/env LIBRATO_AUTORUN=1 bundle exec sidekiq -q "slash-heroku-${RAILS_ENV:="development"}"
