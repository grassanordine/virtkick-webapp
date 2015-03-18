assets = Rails.application.config.assets
Rack::Mime::MIME_TYPES.merge!({'.map' => 'text/plain'})

assets.precompile += %w(*.svg *.eot *.woff *.ttf *.gif *.png *.ico)

module EngineCssLoader
  def include_engines
    out = ''
    Virtkick.engines.each do |gemspec_file|
      dir_name = File.dirname(gemspec_file)
      out += "@import '#{dir_name}';"
    end
    out
  end
end

Rails.application.assets.context_class.instance_eval do
  include EngineCssLoader
end
