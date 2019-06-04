source 'https://rubygems.org'

gem 'activesupport'
gem 'rack'
gem 'puma'
gem 'pg'
gem 'activerecord'
gem 'bugsnag'

group :development do
  gem 'pry'
end

group :deploy do
  gem 'capistrano', '~> 3.2', require: false
  gem 'capistrano3-puma', require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano-dotenv', require: false
  gem 'capistrano-bundler', github: 'capistrano/bundler', require: false
end
