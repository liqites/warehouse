class NStorageService


  def self.get_positions part_id, location
    positions=[]

    ids= NStorage.where(partNr: part_id,
                        ware_house_id: location.whouse_ids).where("n_storages.qty > ?", 0).order(fifo: :asc).pluck(:position_id).uniq
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
      count=NStorage.where(partNr: part.id,  ware_house_id: location.whouse_ids).where("n_storages.qty > ?", 0).sum("qty")
      puts "----------------------------------------------------------------------------------------"
      puts count
      puts "----------------------------------------------------------------------------------------"
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

  # def self.get_remark part, location, qty
  #   if part
  #     count=NStorage.where(partNr: part.id,  ware_house_id: location.whouse_ids).count
  #     if count==0
  #       "零库存"
  #     elsif count<qty
  #       "库存不足"
  #     else
  #       ""
  #     end
  #   else
  #     "仓库无此型号"
  #   end
  # end


end