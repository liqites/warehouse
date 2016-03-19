class StorageOperationRecord < ActiveRecord::Base
  belongs_to :user, foreign_key: :employee_id# :dependent => :destroy

  def self.save_record(params, type)
    record = {
        toWh: params[:toWh],
        toPosition: params[:toPosition],
        type_id: MoveType.find_by!(typeId: type).id,
        employee_id: (params[:employee_id].present? ? params[:employee_id] : (params[:user].present? ? params[:user].id : nil)),
        remarks: (params[:remarks] if params[:remarks].present?),
        fromWh: (params[:fromWh] if params[:fromWh].present?),
        fromPosition: (params[:fromPosition] if params[:fromPosition].present?),
        fifo: (params[:fifo] if params[:fifo].present?),
        partNr: (params[:partNr] if params[:partNr].present?),
        packageId:(params[:packageId] if params[:packageId].present?),
        qty: (params[:qty] if params[:qty].present?)
    }

    puts record
    StorageOperationRecord.create(record)
  end
end
