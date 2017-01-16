class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy, :order_items, :exports]

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
    @orders=OrderService.get_orders_by_days(current_user.location_destination_ids).order(created_at: :desc).all
    @filters = current_user.pick_item_filters
    #@orders = OrderService.get_orders_by_user(current_user.id).order(created_at: :asc).all
    #@start_t = 3.day.ago.localtime.at_beginning_of_day.strftime("%Y-%m-%d %H:00:00")
    #@end_t = Time.now.at_end_of_day.strftime("%Y-%m-%d %H:00:00")
    #@picklists = PickListService.find_by_days(current_user)
  end

  def pick_panel
    #@orders=OrderService.get_orders_by_days(current_user.location.id).order(created_at: :desc).all
    #@filters = current_user.pick_item_filters
    #@orders = OrderService.get_orders_by_user(current_user.id).order(created_at: :asc).all
    @start_t = 1.day.ago.localtime.at_beginning_of_day.strftime("%Y-%m-%d 7:00:00")
    @end_t = Time.now.at_end_of_day.strftime("%Y-%m-%d 7:00:00")
    @picklists = PickListService.find_by_days(current_user)
  end

  def panel_list
    #@orders=OrderService.get_orders_by_days(current_user.location_destination_ids).where.not(id:params[:orders]).order(created_at: :asc).all
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
      @order_items=OrderItem.where(order_id: params[:order_ids]).order(is_emergency: :desc)
      #.group(:part_id,:whouse_id)
      #.select('order_items.*,sum(order_items.quantity) as quantity')
    else
      @order_items=PickItemService.get_order_items(params[:user_id],params[:order_ids]).order(is_emergency: :desc)||[]

    end

    @orders = Order.where(id:params[:order_ids])

    render partial:'item'
  end

  def filters
    @filters = []
    if user = User.find_by_id(params[:user])
      @filters = user.pick_item_filters
    end
    render partial:'filters'
  end

  def filt
    @orders = OrderService.orders_by_filters(params[:user_id],params[:orders],params[:filters])
    render partial:'list'
  end

  def picklists
    user = nil
    if params[:user_id] && user = User.find_by_id(params[:user_id])

    else
      user = current_user
    end
    #
    if params.has_key? :start
      start_t = Time.parse(params[:start]).at_beginning_of_day
      end_t = Time.parse(params[:end]).at_end_of_day
      condition = {
          :user_id => user.id,
          :created_at => start_t..end_t
      }
      @picklists = PickList.where(condition).all.order(created_at: :desc)
    else
      @picklists = PickListService.find_by_days(user)#PickList.where(user_id:params[:user_id]).order(created_at: :desc)
    end

    render partial:'picklists'
  end

  def pickitems
    @picklist= PickList.find(params[:picklist_ids].first)
    @pickitems = PickItem.where(pick_list_id: params[:picklist_ids])
    render partial:'pickitems'
  end

  def order_items
    @order_items = @order.order_items.paginate(:page => params[:page])
  end

  def exports
    send_data(entry_with_xlsx(@order.order_items),
              :type => "application/vnd.openxmlformates-officedocument.spreadsheetml.sheet",
              :filename => "需求单_#{@order.nr}_需求项.xlsx")
  end

  def entry_with_xlsx order_items
    p = Axlsx::Package.new
    wb = p.workbook
    wb.add_worksheet(:name => "Basic Sheet") do |sheet|
      sheet.add_row entry_header
      order_items.each_with_index { |i, index|
        sheet.add_row [
                          index+1,
                          "#{i.order.nr}",
                          OrderItemStatus.display(i.status),
                          i.user.blank? ? '' : i.user.nr,
                          i.quantity,
                          i.part.blank? ? '' : i.part.nr,
                          i.is_emergency ? '是' : '否',
                          i.orderable.blank? ? '' : "#{i.orderable.nr}",
                          i.remarks
                      ], :types => [:string, :string, :string, :string, :string, :string, :string, :string]
      }
    end
    p.to_stream.read
  end

  def entry_header
    ["编号", "择货单号", "状态", "创建者", "数量", "零件号", "是否加急", "料盒编号", "备注"]
  end

  def search
    super { |query|
      unless params[:order][:orderable_id].blank?
        if order_car = OrderCar.find_by_nr(params[:order][:orderable_id])
          query = query.unscope(where: :orderable_id).where(orderable_id: order_car.id)
        end
      end

      query
    }
  end

  def finish_pick
    puts params
    puts '-------------------------------------2'

    OrderService.move_stock_by_finish_pick(params[:pick_list_id], current_user)

    render nothing: true
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
