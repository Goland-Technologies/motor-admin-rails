# frozen_string_literal: true

module Motor
  class ApplicationController < ActionController::Base
    include Motor::CurrentUserMethod
    include Motor::CurrentAbility

    before_action :skip_bullet, unless: -> { Rails.env == "production" }
    before_action :set_title

    def skip_bullet
      Bullet.enable = false
    end

    private

    def set_title
      if !(current_user.super_admin? || current_user.admin?)
        @title = "GoPanel - #{current_user.business.name}"
      else
        @title = "GoPanel - #{current_user.role.titleize}"
      end
    end
  end
end
