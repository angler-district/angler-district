class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  after_action :store_location

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ /\/users/
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  def authorize_seller
    # order = Order.find(@order)
    if @order.seller != current_user
      redirect_back(fallback_location: root_path)# notice: "You are not the seller of this order."
    end
  end

  include Response
  include ExceptionHandler

  def current_user_cart
    "cart#{current_user.id}"
  end

  def remove_from_cart product_id
    $redis.srem current_user_cart, product_id
  end

  def current_user_cart
    "cart#{current_user.id}"
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def resource_class
    User
  end

  helper_method :resource, :resource_name, :devise_mapping, :resource_class

end
