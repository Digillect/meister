source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'activesupport'
gem 'gitlab'
gem 'hashie'
gem 'puma'
gem 'semantic_logger'
gem 'sinatra'
gem 'sucker_punch'
gem 'zeitwerk'

group :development, :test do
  gem 'awesome_print'
  gem 'rubocop'
end

group :test do
  gem 'minitest'
  gem 'minitest-great_expectations'
  gem 'minitest-reporters'
  gem 'rake'
end
