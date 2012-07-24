# Template to get Hoptoad on Padrino
# prereqs:
# sudo gem install rack_hoptoad
# http://github.com/atmos/rack_hoptoad
HOPTOAD = <<-HOPTOAD
    app.use Rack::Hoptoad, 'API_KEY_HERE' do |notifier|
      #notifier.report_under        << 'custom'
      #notifier.environment_filters << %w(MY_SECRET_KEY MY_SECRET_TOKEN)
    end
HOPTOAD
require_dependencies 'rack_hoptoad', :require => 'rack/hoptoad'
initializer :hoptoad,HOPTOAD
inject_into_file destination_root('/app/app.rb'),"    enable :raise_errors\n", :after => "configure do\n"
