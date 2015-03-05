module RequirejsHelper

  def self.included base
    require_config_file = YAML.load_file(Rails.root.join('config', 'requirejs.yml'))

    Dir['engines/*/config/requirejs.yml'].each do |requirejs_file|
      loaded_extension = YAML.load_file(requirejs_file)
      require_config_file = require_config_file.deeper_merge(loaded_extension)
    end

    if Rails.env.production?
      require_config = {baseUrl: '/javascripts'}
    else
      require_config = {baseUrl: '/assets'}
    end

    if require_config_file['shim'] or require_config_file['paths']
      require_config = require_config.deeper_merge({
           shim: require_config_file['shim'],
           paths: require_config_file['paths']
        }
      )
      unless Rails.env.production?
        require_config = require_config.deeper_merge({
               shim: require_config_file['development_shim'],
               paths: require_config_file['paths']
           }
        )
      end
    end
    if Rails.env.production?
      require_config['urlArgs'] = 'v=' + Rails.configuration.version
    end
    @@require_config_json = require_config.to_json
  end

  def requirejs_include_tag *args
    html = ''
    html += '<script src="/require.js"></script>'

    html +=
'''
<script>
require.config(
'''
    html += @@require_config_json
    html += 
'''
);
'''
    html += 'require([' + args.map {|a| '"' + a + '"'}.join(',') + ']);'
    html +=
'''
</script>
'''
    html.html_safe
  end
end