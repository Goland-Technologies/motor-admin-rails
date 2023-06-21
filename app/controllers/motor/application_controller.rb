# frozen_string_literal: true

module Motor
  class ApplicationController < ActionController::Base
    include Motor::CurrentUserMethod
    include Motor::CurrentAbility

    before_action :skip_bullet

    def skip_bullet
      Bullet.enable = false
    end
  end
end
