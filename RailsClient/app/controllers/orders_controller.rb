class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy, :order_items]

  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.unscoped.paginate(:page => params[:page]).order(created_at: :desc)
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)

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

  def panel
    @orders=OrderService.get_orders_by_days(current_user.location.id).order(created_at: :asc).all
    @filters = current_user.pick_item_filters
    #@orders = OrderService.get_orders_by_user(current_user.id).order(created_at: :asc).all
    @picklists = PickList.all
  end

  def panel_list
    @orders=OrderService.get_orders_by_days(current_user.location.id).where.not(id:params[:orders]).order(created_at: :asc).all
    #@orders = OrderService.get_orders_by_user(current_user.id).where.not(id:params[:orders]).order(created_at: :asc).all
    render partial:'list'
  end

  def handle
    orders=[]
    params[:orders].each do |id|
      if order=Order.find_by_id(id)
        order.update(handled:params[:handled])
        orders<<order.id
      end
    end
    render json: orders
  end

  def items
    if params[:user_id].blank?
      @order_items=OrderItem.where(order_id: params[:order_ids])
      #.group(:part_id,:whouse_id)
      #.select('order_items.*,sum(order_items.quantity) as quantity')
    else
      @order_items=PickItemService.get_order_items(params[:user_id],params[:order_ids])||[]
    end
    render partial:'item'
  end

  def filters
    @filters = User.find_by_id(params[:user])
    render partial:'filters'
  end

  def filt
    order_ids=OrderService.get_orders_by_days(current_user.location_id).ids
    @orders = OrderService.filt_orders(current_user.id,order_ids,params[:filters])
    render partial:'list'
  end

  def pickitems
    @pickitems = PickItem.where(pick_list_id: params[:picklist_ids])
    render partial:'pickitems'
  end

  def order_items
    @order_items = @order.order_items.paginate(:page => params[:page])
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_order
    @order = Order.unscoped.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_params
    params.require(:order).permit(:id, :user_id,:handled,:is_delete)
  end
end
