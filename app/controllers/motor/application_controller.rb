# frozen_string_literal: true

module Motor
  class ApplicationController < ActionController::Base
    include Motor::CurrentUserMethod
    include Motor::CurrentAbility

    before_action :skip_bullet, unless: -> {  Rails.env.in?(%w(production  staging)) }
    before_action :set_title
    before_action :set_locale

    def skip_bullet
      Bullet.enable = false
    end

    private

    def set_title
      if current_user.business && !(current_user.super_admin? || current_user.admin?)
        @title = "GoPanel - #{current_user.business.name}"
      elsif current_user.super_admin? || current_user.admin?
        @title = "GoPanel - #{current_user.goland_role.titleize}"
      else
        @title = "GoPanel"
      end
    end

    def set_locale
      locale = session[:locale] || I18n.available_locales.first
      I18n.locale = locale
    end
  end
end
