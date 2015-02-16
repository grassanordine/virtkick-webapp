class DeviseDemoRedirector < Devise::FailureApp
  # Rename to `def route scope` after bumping to Devise 3.4.
  def redirect_url
    mode = Virtkick.mode
    return '/' if mode.none? or mode.demo? or mode.localhost?

    super
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
