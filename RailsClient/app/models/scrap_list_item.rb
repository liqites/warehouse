class ScrapListItem < ActiveRecord::Base
  belongs_to :scrap_list

  def scrap
    # params={
    #     partNr: self.part_id,
    #     qty: self.quantity,
    #     toWh: 'BaofeiKu',
    #     toPosition:'BaofeiWeizhi',
    #     fromWh:'3EX'
    # }
    if self.state==ScrapListItemState::UNHANDLED
      params={
          partNr: self.part_id,
          qty: self.quantity,
          toWh: self.scrap_list.dse_warehouse,
          toPosition: 'BaofeiWeizhi',
          fromWh: self.scrap_list.src_warehouse
      }
      StorageOperationRecord.save_record(params, 'MOVE')
      NStorage.transaction do
        WhouseService.new.move(params)
      end
      self.update_attributes(state: ScrapListItemState::HANDLED)
    end
  end

  def self.generate_report_data(date_start, date_end, src_warehouse, dse_warehouse)

    if date_start.present? && date_end.present?

      if date_end.to_time < date_start.to_time
        raise "登记时间范围选择错误！"
      end
      condition = ""
      if src_warehouse.present? && dse_warehouse.present?
        condition = "WHERE src_warehouse = '#{src_warehouse}' AND dse_warehouse = '#{dse_warehouse}' "
      elsif !src_warehouse.present? && dse_warehouse.present?
        condition = "WHERE dse_warehouse = '#{dse_warehouse}' "
      elsif src_warehouse.present? && !dse_warehouse.present?
        condition = "WHERE src_warehouse = '#{src_warehouse}' "
      end
      ScrapListItem.where(time: Time.parse(date_start).utc.to_s..Time.parse(date_end).utc.to_s).joins("LEFT JOIN (SELECT * FROM scrap_lists #{condition})a ON scrap_list_items.scrap_list_id = a.id")

    elsif !date_start.present? && !date_end.present?

      condition = ""
      if src_warehouse.present? && dse_warehouse.present?
        condition = "WHERE src_warehouse = '#{src_warehouse}' AND dse_warehouse = '#{dse_warehouse}' "
      elsif !src_warehouse.present? && dse_warehouse.present?
        condition = "WHERE dse_warehouse = '#{dse_warehouse}' "
      elsif src_warehouse.present? && !dse_warehouse.present?
        condition = "WHERE src_warehouse = '#{src_warehouse}' "
      end
      ScrapListItem.joins("LEFT JOIN (SELECT * FROM scrap_lists #{condition})a ON scrap_list_items.scrap_list_id = a.id")

    else
      raise "登记时间范围选择错误！"
    end

  end

end
