class InventoryListsController < ApplicationController
  before_action :set_inventory_list, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @inventory_lists = InventoryList.all
    respond_with(@inventory_lists)
  end

  def show
    respond_with(@inventory_list)
  end

  def new
    @inventory_list = InventoryList.new
    respond_with(@inventory_list)
  end

  def edit
  end

  def create
    @inventory_list = InventoryList.new(inventory_list_params)
    @inventory_list.save
    respond_with(@inventory_list)
  end

  def update
    @inventory_list.update(inventory_list_params)
    respond_with(@inventory_list)
  end

  def destroy
    @inventory_list.destroy
    respond_with(@inventory_list)
  end

  private
    def set_inventory_list
      @inventory_list = InventoryList.find(params[:id])
    end

    def inventory_list_params
      params.require(:inventory_list).permit(:name, :state, :whouse_id, :user_id)
    end
end
