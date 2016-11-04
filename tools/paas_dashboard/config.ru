require 'dashing'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'
  set :default_dashboard, 'paas-overview'
  set :protection, except: :frame_options

  helpers do
    def protected!
      # Put any authentication code you want in here.
      # This method is run before accessing any resource.
      # See https://github.com/Shopify/dashing/wiki/How-to:-Add-authentication
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
