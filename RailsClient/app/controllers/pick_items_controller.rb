class PickItemsController < ApplicationController
  before_action :set_pick_item, only: [:show, :edit, :update, :destroy]

  # GET /pick_items
  # GET /pick_items.json
  def index
    @pick_items = PickItem.paginate(:page => params[:page]).order(created_at: :desc)#all
  end

  # GET /pick_items/1
  # GET /pick_items/1.json
  def show
  end

  # GET /pick_items/new
  def new
    @pick_item = PickItem.new
  end

  # GET /pick_items/1/edit
  def edit
  end

  # POST /pick_items
  # POST /pick_items.json
  def create
    @pick_item = PickItem.new(pick_item_params)

    respond_to do |format|
      if @pick_item.save
        format.html { redirect_to @pick_item, notice: '新建成功' }
        format.json { render :show, status: :created, location: @pick_item }
      else
        format.html { render :new }
        format.json { render json: @pick_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pick_items/1
  # PATCH/PUT /pick_items/1.json
  def update
    respond_to do |format|
      if @pick_item.update(pick_item_params)
        format.html { redirect_to pick_items_url, notice: '更新成功.' }
        format.json { render :show, status: :ok, location: @pick_item }
      else
        format.html { render :edit }
        format.json { render json: @pick_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pick_items/1
  # DELETE /pick_items/1.json
  def destroy
    @pick_item.destroy
    respond_to do |format|
      format.html { redirect_to pick_items_url, notice: '删除成功.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pick_item
      @pick_item = PickItem.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pick_item_params
      params.require(:pick_item).permit(:id, :part_id, :quantity,:box_quantity,:destination_whouse_id,:state)
    end
end
