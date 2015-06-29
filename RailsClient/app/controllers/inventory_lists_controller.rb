class InventoryListsController < ApplicationController
  before_action :set_inventory_list, only: [:show, :edit, :update, :destroy, :inventory_list_items]

  respond_to :html

  def index
   
    @inventory_lists = InventoryList.paginate(:page => params[:page])
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
    @inventory_list.user_id = current_user.id
    @inventory_list.save
    respond_to do |format|
      if @inventory_list.save
        format.html { redirect_to @inventory_list, notice: 'InventoryList was successfully created.' }
        format.json { render :show, status: :created, location: @inventory_list }
      else
        format.html { render :new }
        format.json { render json: @inventory_list.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @inventory_list.update(inventory_list_params)
    respond_with(@inventory_list)
  end

  def destroy
    @inventory_list.destroy
    respond_with(@inventory_list)
  end
  
  def inventory_list_items
    @inventory_list_items = @inventory_list.inventory_list_items.paginate(:page => params[:page])
    @page_start=(params[:page].nil? ? 0 : (params[:page].to_i-1))*20
  end
  
  def discrepancy
    @inventory_list_id = params[:sid]||params[:id]
    @inventory_list=InventoryList.find_by_id(@inventory_list_id)
    @results = NStorage.generate_diff_report(@inventory_list_id)
    
    @title="#{InventoryList.find_by(:id => @inventory_list_id).name}差异报表"
    # @inventory_list_items = InventoryListItem.all
    # puts @inventory_list_items.first.part_id
    respond_to do |format|
      format.csv do
        send_data(order_report_csv(@results),
                  :type => "text/csv;charset=utf-8; header=present",
                  :filename => @title+".csv")
      end

      format.xlsx do
        send_data(order_report_xlsx(@results),
                  :type => "application/vnd.openxmlformates-officedocument.spreadsheetml.sheet",
                  :filename => @title+".xlsx"
        )
      end

      format.html
    end
  end


  def export_total
    msg = FileHandler::Excel::InventoryListItemHandler.export_total_no_fifo(
        InventoryListItem.joins(:inventory_list).where(inventory_lists:{state:InventoryListState::PROCESSING}).group('part_id').select('*,sum(qty) as qty')
    )
    send_file msg.content
  end
    
  private
    def set_inventory_list
      @inventory_list = InventoryList.find(params[:id])
    end

    def inventory_list_params
      params.require(:inventory_list).permit(:name, :state, :whouse_id, :user_id)
    end
    
    def order_report_xlsx results
      p = Axlsx::Package.new
      wb = p.workbook
      wb.add_worksheet(:name => "Basic Sheet") do |sheet|
        sheet.add_row ["No.", "零件号", "库存数量", "盘点数量", "差异数（库存数-盘点数）"]
        results.each_with_index { |o, index|
          sheet.add_row [
                    index+1,
                    o[0],
                    o[1],
                    o[2],
                    o[3]
                   ], :types => [:string]
          # removal_packages["#{o.part_id}#{o.whouse_id}"] = nil
        }
      end
      p.to_stream.read
    end
    
    def order_report_csv results
      CSV.generate do |csv|
        csv << ["No.", "零件号", "库存数量", "盘点数量", "差异数（库存数-盘点数）"]
        results.each.each_with_index { |o, index|
          csv <<[
              index+1,
              o[0],
              o[1],
              o[2],
              o[3]
          ]   
          # removal_packages["#{o.part_id}#{o.whouse_id}"] = nil
        }
      end
    end
end
