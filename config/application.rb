require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module VirtkickWebapp
  class Application < Rails::Application
    $LOAD_PATH.unshift Rails.root

    # config.time_zone = 'Pacific Time (US & Canada)'
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    config.autoload_paths += %W(
      #{config.root}/app/lib
    )

    ENV['PATH'] = "#{Rails.root.join('bin')}:#{ENV['PATH']}"
    Virtkick.engines.each do |gemspec_file|
      engine_dir = File.dirname gemspec_file

      bin_dir = Rails.root.join engine_dir, 'bin'
      ENV['PATH'] = "#{bin_dir}:#{ENV['PATH']}"

      config.autoload_paths += ["#{config.root}/#{engine_dir}/lib"]
    end

    config.active_record.raise_in_transactional_callbacks = true

    config.active_support.deprecation = :notify
    config.log_level = :warn
    config.log_formatter = ::Logger::Formatter.new
    config.autoflush_log = true

    config.serve_static_files = true

    config.assets.digest = true
    config.assets.enabled = true
    config.assets.compile = true
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

    begin
      config.theme = IO.read(Rails.root.join('.theme')).strip
    rescue => ignored
      config.theme = ENV['VIRTKICK_THEME'] || 'default'
    end
    version = `git rev-parse --short HEAD 2> /dev/null || cat .version 2> /dev/null || echo unknown`.chop

    unless File.basename($0) == "rake"
      puts "App configured for version #{version}"
    end

    config.version = config.assets.version = version + '-' + config.theme


    %w(fonts images stylesheets).each do |dir|
      if config.theme == 'default'
        config.assets.paths << Rails.root.join('app', 'default-theme', dir)
      else
        config.assets.paths << Rails.root.join('app', 'themes', config.theme, dir)
      end
    end

    config.assets.precompile += %w(.svg .eot .woff .ttf)
    config.stylesheets_dir = '/css'

    config.active_job.queue_adapter = :delayed_job

    demo_timeout = ENV['VIRTKICK_DEMO_TIMEOUT'] || 30
    config.x.demo_timeout = demo_timeout.to_i

    config.after_initialize do
      bin_name = File.basename $0
      unless %w(rake rspec).include? bin_name
        CountDeploymentJob.track CountDeploymentJob::APP_START_SUCCESS
      end
    end
  end
end
