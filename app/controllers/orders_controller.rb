class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.all
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    # cart_ids = $redis.smembers current_user_cart
    # @cart_products = Product.find(cart_ids)
    @product = Product.find(@order.product_id)
  end

  # GET /orders/new
  def new
    @order = Order.new
    # @product = Product.find(params[:product_id])
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  # POST /orders.json
  def create
    @cart_ids = $redis.smembers current_user_cart
    if @cart_ids.count == 1
      @order = Order.new(order_params)
      @product = Product.find(@cart_ids).first
      @seller = User.find(@product.user_id)
      @order.product_id = @product.id
      @order.buyer_id = current_user.id
      @order.seller_id = @seller.id
      @order.save
      if @order.save
        @product.set_inventory_to_zero
      end
      remove_from_cart @product.id
    else
      @cart_ids.each do |id|
        @order = Order.new(order_params)
        @product = Product.find(id)
        @seller = @product.user
        @order.product_id = @product.id
        @order.buyer_id = current_user.id
        @order.seller_id = @seller.id
        @order.save
        if @order.save
          @product.set_inventory_to_zero
        end
        remove_from_cart @product.id
      end
    end

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: 'Order was successfully created.' }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
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
      params.require(:order).permit(:address, :city, :state)
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
end
