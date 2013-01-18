module Masq
  class SessionsController < BaseController
    before_filter :login_required, :only => :destroy
    after_filter :set_login_cookie, :only => :create

    def new
      redirect_after_login if logged_in?
    end

    def create
      certificate = request.env['SSL_CLIENT_CERT']
        .gsub(/\r\n|\n/, "\n").chomp rescue nil

      a   = Account.authenticate_by_ssl_certificate(certificate) if certificate
      a ||= Account.authenticate(params[:login], params[:password])

      self.current_account = a

      if logged_in?
        flash[:notice] = t(:you_are_logged_in)
        redirect_after_login
      else
        if a.nil?
          redirect_to login_path, :alert => t(:login_incorrect)
        elsif a.active? && a.enabled?
          redirect_to login_path, :alert => t(:password_incorrect)
        elsif not a.enabled?
          redirect_to login_path, :alert => t(:account_disabled)
        else
          redirect_to login_path(:resend_activation_for => params[:login]), :alert => t(:account_not_yet_activated)
        end
      end
    end

    def destroy
      current_account.forget_me
      cookies.delete :auth_token
      reset_session
      redirect_to root_path, :notice => t(:you_are_now_logged_out)
    end

    private

    def set_login_cookie
      if logged_in? and params[:remember_me] == '1'
        current_account.remember_me
        cookies[:auth_token] = {
          :value => current_account.remember_token,
          :expires => current_account.remember_token_expires_at }
      end
    end

    def redirect_after_login
      if return_to = session[:return_to]
        session[:return_to] = nil
        redirect_to return_to
      else
        redirect_to identity_path(current_account)
      end
    end
  end
end
