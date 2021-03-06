Devise.setup do |config|
  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'
  require 'devise/orm/active_record'

  if Rails.env.production?
    config.secret_key = ENV['DEVISE_SECRET_KEY']
    raise 'Set the DEVISE_SECRET_KEY environment variable for production.' unless config.secret_key
  end

  config.authentication_keys = [:email]
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 10
  # config.pepper = # TODO
  config.reconfirmable = true
  config.remember_for = 1.year
  config.expire_all_remember_me_on_sign_out = true
  # Options to be passed to the created cookie. For instance, you can set
  # secure: true in order to force SSL only cookies.
  config.rememberable_options = {}
  config.password_length = 8..128
  # config.email_regexp = /\A[^@]+@[^@]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :get # TODO: change to :delete before merging into master

  config.parent_controller = 'SpaController'

  config.warden do |manager|
    manager.failure_app = DeviseDemoRedirector
  end
end

Rails.application.config.to_prepare do
  Devise::SessionsController.layout 'raw'
  Devise::RegistrationsController.layout proc { |controller| user_signed_in? ? 'application' : 'raw' }
  Devise::ConfirmationsController.layout 'raw'
  Devise::UnlocksController.layout 'raw'
  Devise::PasswordsController.layout 'raw'
end

Devise::RegistrationsController
class Devise::RegistrationsController < DeviseController
  before_action do |controller|
    action = controller.action_name
    raise 'Not allowed.' if action == 'destroy'

    if %w(new create).include?(action) and not Virtkick.mode.vps_provider?
      raise 'Not allowed.'
    end
  end
end
