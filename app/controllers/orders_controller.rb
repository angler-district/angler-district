class OrdersController < ApplicationController
  before_action :set_order, only: [:purchase, :edit, :update, :destroy, :show, :charged]
  before_action :authenticate_user!
  # before_action :check_user, only: [:edit, :update, :destroy]
  # before_action :check_shipper,
  before_action :check_buyer, only: [:show, :edit, :update, :destroy, :purchase, :charged]

  # GET /orders
  # GET /orders.json
  def index
    @to_ship_orders = Order.to_ship(current_user.id)
    @purchased_orders = Order.user_purchased(current_user.id)
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @order = Order.find(params[:id])
    @product = Product.find(@order.product_id)
    @total = @product.price
  end

  # GET /orders/new
  def new
    @order = Order.new
    @cart_ids = $redis.smembers current_user_cart
    @product = Product.where(slug: @cart_ids.first).first
    price_total = @product.price
    shipping_total = @product.shipping
    @total = price_total + shipping_total
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)
    @cart_ids = $redis.smembers current_user_cart
    @product = Product.where(slug: @cart_ids).first
    @seller = User.find(@product.user_id)
    @order.total = @product.price
    @order.product_id = @product.id
    @order.buyer_id = current_user.id
    @order.seller_id = @seller.id
    @order.save
    # test mailer
    puts "test mailer"
    # ItemPurchasedMailer.alert_seller(@seller, @order, @product, current_user).deliver_now

    OrderProduct.create({product_id: @product.id, order_id: @order.id})
    respond_to do |format|
      if @order.save
        format.html {
          # flash[:notice] = 'Order was successfully created.'
          redirect_to action: "purchase", id: @order.id
        }
        format.json { render :purchase, status: :created, location: @order }
      else
        format.html { render :new }
        format.json {
          render json: @order.errors, status: :unprocessable_entity
        }
      end
    end
  end

  def show
    @orders = Order.charged(current_user.id)
  end

  def sold_orders
    @orders = Order.charged(current_user.id)
  end

  def purchase
    @total = @order.product.price + @order.product.shipping
  end

  def submitted_orders
    @orders = Order.charged(current_user.id)
  end

  def charged
    @order = Order.find(params[:id])
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:address1, :address2, :city, :state, :first_name, :last_name, :zip_code)
    end

    def current_user_cart
      "cart#{current_user.id}"
    end

    def remove_from_cart product_id
      $redis.srem current_user_cart, product_id
    end

    def current_user_cart
      "cart#{current_user.id}"
    end

    def check_user
      if current_user != @product.user
        redirect_to root_url, alert: "Sorry, this product belongs to someone else"
      end
    end

    def check_buyer
      if current_user.id != @order.buyer_id
        redirect_to root_url, flash[:notice] = "Sorry, this order belongs to someone else"
      end
    end
end
