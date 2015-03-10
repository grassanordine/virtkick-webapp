source 'https://rubygems.org'

ruby '2.1.5'

gem 'rake', '10.1.0'
gem 'active_hash'
gem 'activemodel'
gem 'auto_strip_attributes', '~> 2.0'
gem 'bootstrap-sass', '~> 3.1'
gem 'bugsnag'
gem 'coffee-rails', '~> 4.1.0'
gem 'daemons'
gem 'debug_inspector'
gem "deep_merge", :require => 'deep_merge/rails_compat'
gem 'devise', '~> 3.4.0'
gem 'font-awesome-rails'
gem 'ipaddress', '~> 0.8.0'
gem 'jbuilder', '~> 2.0'
gem 'jquery-rails'
gem 'httparty'
gem 'multimap'
gem 'puma' unless ENV['PACKAGING']
gem 'rails', '4.2.0'
gem 'twitter-bootstrap-rails-confirm', git: 'https://github.com/bluerail/twitter-bootstrap-rails-confirm.git'
gem 'rails-html-sanitizer', '~> 1.0'
gem 'rails_bootstrap_navbar'
gem 'recursive-open-struct'
gem 'responders', '~> 2.0'
gem 'sass-rails', '~> 5.0.1'
gem 'sass-globbing'
gem 'slim'
gem 'uglifier', '>= 1.3.0'
gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'
gem 'whenever', :require => false
gem 'hooks'

# These require native extensions. Ensure Traveling Ruby provides an appropriate version before bumping.
gem 'bcrypt', '3.1.9'
gem 'nokogiri', '1.6.5'
gem 'sqlite3', '1.3.9'


group :development, :test do
  gem 'rspec-rails'
  gem 'spring'
  gem 'web-console', '2.0.0'
end unless ENV['PACKAGING']

group :development do
  gem 'rb-fsevent', require: false
end unless ENV['PACKAGING']

group :test do
  gem 'codeclimate-test-reporter'
  gem 'timecop'
  gem 'webmock'
end unless ENV['PACKAGING']

# Gems that need to be required as last
gem 'delayed_job', git: 'https://github.com/Nowaker/delayed_job.git', branch: 'feature/exception-in-failure-hook'
gem 'delayed_job_active_record', '~> 4.0', git: 'https://github.com/Nowaker/delayed_job_active_record.git'


if File.exists?('Gemfile.local')
  eval File.read('Gemfile.local'), nil, 'Gemfile.local'
end


## plugins
Dir['engines/*/*.gemspec'].each do |gemspec_file|
  dir_name = File.dirname(gemspec_file)
  gem_name = File.basename(gemspec_file, File.extname(gemspec_file))

  # sometimes "-" and "_" are used interchangeably in gems
  # for e.g. gemspec_file is "engines/my-engine/my_engine.gemspec"
  #   dir_name will be engines/my-engine
  #   gem_name will be my_engine


  # Register that engine as a dependency, *without* being required
  gem gem_name, :path => dir_name, :require => true

  # e.g. this is similar to saying
  #  gem 'my_engine', :path => 'engines/my-engine', :require => false
end
