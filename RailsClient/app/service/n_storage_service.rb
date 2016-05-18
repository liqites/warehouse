class NStorageService


  def self.get_positions part_id, location
    positions=[]

    ids= NStorage.where(partNr: part_id,
                        ware_house_id: location.whouse_ids).order(fifo: :asc).pluck(:position_id).uniq
    ids.each do |id|
      if p=Position.find_by_id(id)
        positions<<p.nr
      end
    end
    positions.join(';')
  end

  def self.get_total_stock_count part_id, location
    # if storage=NStorage.select("SUM(n_storages.qty) as total").where(partNr: part_id).first
    #   storage.total
    # else
    #   0
    # end

    NStorage.where(partNr: part_id,
                   ware_house_id: location.whouse_ids).count
  end

  def self.get_remark part, location, qty
    if part
      count=NStorage.where(partNr: part.id, ware_house_id: location.whouse_ids).count
      if count==0
        "零库存"
      elsif count<qty
        "库存不足"
      else
        ""
      end
    else
      "仓库无此型号"
    end
  end

  def self.get_mrp_part_stock_by_nrs part_nrs
    get_part_stock_by_nrs(part_nrs, Whouse.mrp_whouses)
  end

  def self.get_part_stock_by_nrs part_nrs, whouses=nil
    q= NStorage.where(partNr: part_nrs)
    if whouses.present?
      q=q.where(ware_house_id: whouses.pluck(:id))
    end
    q.joins('inner join parts on n_storages.partNr=parts.id').group(:partNr)
        .select('sum(n_storages.qty) as qty,n_storages.fifo,n_storages.partNr,parts.unit')
  end

  def self.move_stock data
    msg=move_stock_check data

    if msg.result
      NStorage.transaction do
        data.each do |d|
          p data
          part=Part.find_by_nr(d[:part_id])
          if [MATERIAL_ADD, MATERIAL_MOVE, SEMIFINISHED_MOVE, FINISHED_MOVE, SCRAP_ADD, SCRAP_MOVE, REWORK_ADD, REWORK_MOVE].include?(d[:result_code])
            if KskResultState::FINISHED_ADD==d[:result_code]
              w=Whouse.find_by_nr('Finished')
            elsif KskResultState::SEMIFINISHED_ADD==d[:result_code]
              w=Whouse.find_by_nr('SemiFinished')
            end
            WhouseService.new.enter_stock({
                                              partNr: part.id,
                                              qty: 1,
                                              fifo: Time.now(),
                                              toWh: w.id,
                                              toPosition: w.default_position.id,
                                              packageId: d[:package_id]
                                          })
          elsif [MATERIAL_ADD, MATERIAL_MOVE, SEMIFINISHED_MOVE, FINISHED_MOVE, SCRAP_ADD, SCRAP_MOVE, REWORK_ADD, REWORK_MOVE].include?(d[:result_code])

          else
          end
        end
      end
    else
      return {result_code: 0, messages: msg.content}
    end

    {
        result_code: 1,
        messages: "Success"
    }
  end

  def self.move_stock_check data
    msg=Message.new(contents: [])

    data.each do |d|
      if [KskResultState::FINISHED_ADD, KskResultState::SEMIFINISHED_ADD].include?(d[:result_code])
        if d[:package_id].blank?
          msg.contents << "唯一码不能为空"
        end
        if NStorage.exists_package?(d[:package_id])
          msg.contents << "唯一码已存在"
        end
        unless Part.find_by_nr(d[:part_id])
          msg.contents << "零件号不存在"
        end
      elsif [MATERIAL_ADD, MATERIAL_MOVE, SEMIFINISHED_MOVE, FINISHED_MOVE, SCRAP_ADD, SCRAP_MOVE, REWORK_ADD, REWORK_MOVE].include?(d[:result_code])

      else
        msg.contents << "result code 不正确"
      end
    end

    unless msg.result=(msg.contents.size==0)
      msg.content=msg.contents.join('/')
    end
    msg
  end


end