class NoCompression
  def compress(string)
    # do nothing
    string
  end
end

Rails.application.configure do
  # delayed jobs always reload classes which breaks hooks
  bin_name = File.basename $0
  if bin_name == 'rake'
    config.cache_classes = true
  else
    config.cache_classes = false
  end

  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  config.action_mailer.raise_delivery_errors = false
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.action_view.raise_on_missing_translations = true

  if ENV['INLINE']
    config.active_job.queue_adapter = :inline
  end
  config.assets.digest = false
  config.assets.debug = true
  config.assets.raise_runtime_errors = true

  # only for development since digest is off
  config.assets.paths << Rails.root.join('app', 'javascripts')
  Dir['engines/*/*.gemspec'].each do |gemspec_file|
      dir_name = File.dirname(gemspec_file)
      config.assets.paths << Rails.root.join(dir_name, 'app', 'javascripts')

      config.sass.load_paths << Rails.root.join(dir_name, 'app', 'assets', 'stylesheets')
  end
end
