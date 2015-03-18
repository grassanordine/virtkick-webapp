PACKAGE_NAME = "virtkick-webapp"
TRAVELING_RUBY_VERSION = "20141213-2.1.5"
SQLITE3_VERSION = "1.3.9"
NOKOGIRI_VERSION = "1.6.5"
BCRYPT_VERSION = "3.1.9"

require 'bundler/setup'

desc "Package your app"
task :package => [ 'package:linux:x86_64' ]

ENV['DEVISE_SECRET_KEY'] = 'willbereplaced'
ENV['SECRET_KEY_BASE'] = 'willbereplaced'

namespace :package do
  namespace :linux do
    desc "Package your app for Linux x86_64"
    task :x86_64 => [:bundle_install,
      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz",
      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-sqlite3-#{SQLITE3_VERSION}.tar.gz",
      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-nokogiri-#{NOKOGIRI_VERSION}.tar.gz",
      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-bcrypt-#{BCRYPT_VERSION}.tar.gz"
    ] do
      create_package("linux-x86_64")
    end
  end

 desc "Install gems to local directory"
  task :bundle_install do
    if RUBY_VERSION !~ /^2\.1\./
      abort "You can only 'bundle install' using Ruby 2.1, because that's what Traveling Ruby uses."
    end
    sh "rm -rf packaging/tmp"
    sh "mkdir -p packaging/tmp packaging/tmp/engines"
    sh "cp Gemfile packaging/tmp/"

    mod = ENV['MODULE']
    if mod and mode != 'basic'
      sh "cp -r ../modules/#{mod} packaging/tmp/engines"
    end

    Bundler.with_clean_env do
      sh "cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=1 NOKOGIRI_USE_SYSTEM_LIBRARIES=1 PACKAGING=1 bundle install --path ../vendor --without development test"
    end
    sh "rm -rf packaging/vendor/*/*/cache/*"
    sh "rm -rf packaging/vendor/ruby/*/extensions"
    sh "find packaging/vendor/ruby/*/gems -name '*.so' | xargs rm -f"
    sh "find packaging/vendor/ruby/*/gems -name '*.bundle' | xargs rm -f"
  end

end


file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
  download_runtime("linux-x86_64")
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-sqlite3-#{SQLITE3_VERSION}.tar.gz" do
  download_native_extension("linux-x86_64", "sqlite3-#{SQLITE3_VERSION}")
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-nokogiri-#{NOKOGIRI_VERSION}.tar.gz" do
  download_native_extension("linux-x86_64", "nokogiri-#{NOKOGIRI_VERSION}")
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-bcrypt-#{BCRYPT_VERSION}.tar.gz" do
  download_native_extension("linux-x86_64", "bcrypt-#{BCRYPT_VERSION}")
end

def create_package(target)
  package_dir = "#{PACKAGE_NAME}-#{target}"
  sh "rm -rf #{package_dir}"
  sh "mkdir #{package_dir}"
  sh "mkdir -p #{package_dir}/lib/app"
  sh "cp -r config.ru Rakefile bin app config lib public spec db vendor #{package_dir}/lib/app/"
  sh "rm -rf #{package_dir}/lib/app/vendor/cache #{package_dir}/lib/app/db/*.sqlite3"
  sh "mkdir #{package_dir}/lib/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/lib/ruby"
  sh "cp packaging/wrapper-common.sh #{package_dir}/lib"
  sh "cp packaging/virtkick-webapp packaging/virtkick-work #{package_dir}"
  sh "cp -pR packaging/vendor #{package_dir}/lib/"
  sh "cp packaging/tmp/Gemfile packaging/tmp/Gemfile.lock #{package_dir}/lib/vendor/"
  mod = ENV['MODULE']
  if mod and mod != 'basic'
    sh "mkdir -p #{package_dir}/lib/app/engines"
    sh "mv packaging/tmp/engines/#{mod} #{package_dir}/lib/app/engines"
  end
  sh "rm -rf packaging/tmp"
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}-sqlite3-#{SQLITE3_VERSION}.tar.gz " +
    "-C #{package_dir}/lib/vendor/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}-nokogiri-#{NOKOGIRI_VERSION}.tar.gz " +
    "-C #{package_dir}/lib/vendor/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}-bcrypt-#{BCRYPT_VERSION}.tar.gz " +
    "-C #{package_dir}/lib/vendor/ruby"
  unless ENV['DIR_ONLY']
    sh "tar -Jcf #{package_dir}.tar.xz #{package_dir}"
    sh "rm -rf #{package_dir}"
  end
end

def download_runtime(target)
  sh "cd packaging && curl -L -O --fail " +
    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end

def download_native_extension(target, gem_name_and_version)
  sh "curl -L --fail -o packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}-#{gem_name_and_version}.tar.gz " +
    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-gems-#{TRAVELING_RUBY_VERSION}-#{target}/#{gem_name_and_version}.tar.gz"
end
