assets = Rails.application.config.assets
Rack::Mime::MIME_TYPES.merge!({'.map' => 'text/plain'})

# We don't want application.css to be included in `rake assets:precompile`
# If ever the way it's defined changes in Rails, we'll have an exception.
old = Rails.configuration.assets.precompile.delete /(?:\/|\\|\A)application\.(css|js)$/
raise 'Did you update Rails?' unless old

assets.precompile += %w(*.svg *.eot *.woff *.ttf *.gif *.png *.ico application-*.css)

module EngineCssLoader
  def include_engines
    out = ''
    Dir['engines/*/*.gemspec'].each do |gemspec_file|
      dir_name = File.dirname(gemspec_file)
      out += "@import '#{dir_name}';"
    end
    out
  end
end

Rails.application.assets.context_class.instance_eval do
  include EngineCssLoader
end
