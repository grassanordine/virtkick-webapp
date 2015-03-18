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
gem 'deep_merge', require: 'deep_merge/rails_compat'
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
gem 'whenever', require: false
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
  gem 'guard', require: false
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
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

## Modules
unless ENV['COMMIT']
  # Gemfile is in a different location depending on a situation.
  if ENV['PACKAGED']
    # /opt/virtkick/webapp/lib/vendor/Gemfile - one level down to Rails.root, then go to 'app'
    require_relative '../app/app/lib/virtkick'
  elsif ENV['PACKAGING']
    # virtkick-package/webapp/packaging/tmp/Gemfile - two levels down to Rails.root
    require_relative '../../app/lib/virtkick'
  else
    # virtkick-package/webapp/Gemfile
    require_relative 'app/lib/virtkick'
  end

  Virtkick.engines.each do |gemspec_file|
    dir_name = File.dirname gemspec_file
    gem_name = File.basename gemspec_file, File.extname(gemspec_file)

    if ENV['PACKAGED']
      dir_name = '../app/' + dir_name
    end

    gem gem_name, path: dir_name, require: true
  end
end
