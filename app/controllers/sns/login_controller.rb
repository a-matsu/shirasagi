class Sns::LoginController < ApplicationController
  include Sns::BaseFilter

  protect_from_forgery except: :remote_login
  skip_filter :logged_in?, only: [:login, :remote_login]

  navi_view nil

  private
    def get_params
      params.require(:item).permit(:email, :password)
    end

  public
    def login
      if !request.post?
        # retrieve parameters from get parameter. this is bookmark support.
        @item = SS::User.new
        @item.email = params[:email]
        @item.password = params[:password]
        return
      end

      safe_params = get_params
      email_or_uid = safe_params[:email]
      password = safe_params[:password]

      @item = SS::User.authenticate(email_or_uid, password)
      return if !@item

      if params[:ref].blank? || [sns_login_path, sns_mypage_path].index(params[:ref])
        return set_user @item, session: true, redirect: true, password: password
      end

      set_user @item, session: true, password: password
      render :redirect
    end

    def remote_login
      raise "404" unless SS::config.sns.remote_login

      login
      render :login if response.body.blank?
    end

    def logout
      put_history_log
      unset_user redirect: true
    end
end
