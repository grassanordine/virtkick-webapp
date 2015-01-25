require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module VirtkickWebapp
  class Application < Rails::Application
    # config.time_zone = 'Pacific Time (US & Canada)'
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    config.autoload_paths += %W(
      #{config.root}/app/lib
    )

    config.active_record.raise_in_transactional_callbacks = true

    config.active_support.deprecation = :notify
    config.log_level = :warn
    config.log_formatter = ::Logger::Formatter.new
    config.autoflush_log = true

    config.serve_static_files = true

    config.assets.digest = true
    config.assets.enabled = true

    config.assets.compile = true
    config.assets.version = '1.0'
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.assets.precompile += %w(.svg .eot .woff .ttf)
    config.stylesheets_dir = '/css'

    config.active_job.queue_adapter = :delayed_job

    config.x.demo = false
    config.x.demo_timeout = false
    if ENV['DEMO']
      timeout = ENV['DEMO_TIMEOUT'] || 30
      config.x.demo = true
      config.x.demo_timeout = timeout.to_i
    end

    config.after_initialize do
      bin_name = File.basename $0
      unless %w(rake rspec).include? bin_name
        CountDeploymentJob.track CountDeploymentJob::APP_START_SUCCESS
      end
    end
  end
end
