# SSL Certificate Login

For quick testing of the SSL certificate login with webrick, add the following
lines to `script/rails` in a project, which includes the masq engine.

    require 'rubygems'
    require 'rails/commands/server'
    require 'rack'
    require 'webrick'
    require 'webrick/https'

    module Rails
      class Server < ::Rack::Server
        def default_options
          super.merge({
            :Port => 3443,
            :environment => (ENV['RAILS_ENV'] || 'development').dup,
            :daemonize => false,
            :debugger => false,
            :pid => File.expand_path('tmp/pids/server.pid'),
            :config => File.expand_path('config.ru'),
            :SSLEnable => true,
            :SSLVerifyClient => OpenSSL::SSL::VERIFY_PEER,
            :SSLPrivateKey => OpenSSL::PKey::RSA.new(File.open(File.expand_path('test.key')).read),
            :SSLCertificate => OpenSSL::X509::Certificate.new(File.open(File.expand_path('test.crt')).read),
            :SSLCACertificatePath => '/etc/ssl/certs',
            :SSLCertName => [['CN', 'localhost']]
          })
        end
      end
    end

The SSL private key (`test.key`) and server certificate (`test.crt`) have to
exist in the rails app root. You can generate dummy certificates with the
following commands for example.

  * `openssl genrsa 2048 > test.key`
  * `openssl req -new -x509 -nodes -sha1 -days 1095 -key test.key > test.crt`

In `config/masq.yml` the options `use_ssl` and `can_use_ssl_login` have to be
`true`.
