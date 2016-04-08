class WhouseService
  def validate_fifo_time(fifo)
    return nil if fifo.blank?
    puts "---------------88888888888#{fifo}"
    t = fifo.to_time
    raise "fifo:#{fifo} 无效" if t > Time.now
    t
  end

  def validate_position_pattern(positionPattern)
    # convert position to Regex object, if no exception raised, it's valid
    /"#{positionPattern}/
  end

  def validate_position(wh, position)
    regex = wh.positionPattern ? /"#{wh.positionPattern}/ : nil
    raise 'position pattern is invalid' if not position.present? or regex and regex.match(position).nil?
  end

  def get_fifo_time_range(fifo)
    [fifo[:start].to_time, fifo[:end].to_time]
  end

  def create_whouse(params)
    puts '----------------'
    if location = Location.find_by(id: params[:locationId])
      validate_position_pattern(params[:positionPattern])
      wh = Whouse.create!(id: params[:id], name: params[:name], position_pattern: params[:positionPattern],
                          location_id: location.id)
    else
      raise 'locationId does not exists'
    end
  end

  def enter_stock(params)
    # raise '盘点模式,非超级管理员权限不可更改数据!' if (SysConfigCache.inventory_enable_value=='true' && !params[:user].supermanager?)
    # validate fifo
    # PaperTrail.whodunnit = params[:user].blank? ? '' : params[:user].id
    user_id=params[:user].blank? ? params[:employee_id] : params[:user].id
    PaperTrail.whodunnit = user_id

    puts '----------------------ss'
    fifo = validate_fifo_time(params[:fifo])
    # validate whId existing
    wh = Whouse.find_by(id: params[:toWh])
    raise '仓库未找到' unless wh
    # validate uniqueId
    raise 'uniqueId 已存在!' if params[:uniqueId].present? and NStorage.find_by(params[:uniqueId])

    if params[:packageId] and NStorage.find_by(packageId: params[:packageId], partNr: params[:partNr])
      raise "该唯一码#{params[:packageId]}已入库！"
    else
      data = {partNr: params[:partNr], qty: params[:qty], fifo: fifo, ware_house_id: wh.id, position: params[:toPosition]}
      data[:uniqueId] = params[:uniqueId] if params[:uniqueId].present?
      data[:packageId] = params[:packageId] if params[:packageId].present?
      data[:locked]=true if params[:locked].present?
      if params[:packageId].present?
        NStorage.create!(data)
      else
        storage = NStorage.where(partNr: params[:partNr], ware_house_id: wh.id, position: params[:toPosition], packageId: nil).order("n_storages.qty asc").first

        if storage
          storage.update!(qty: storage.qty + params[:qty].to_f)
        else
          NStorage.create!(data)
        end
      end
    end
    type = MoveType.find_by!(typeId: 'ENTRY')
    data = {fifo: fifo, partNr: params[:partNr], qty: params[:qty], to_id: wh.id, toPosition: params[:toPosition],
            type_id: type.id}
    data[:uniqueId] = params[:uniqueId] if params[:uniqueId].present?
    data[:packageId] = params[:packageId] if params[:packageId].present?
    data[:employee_id] = params[:employee_id] if params[:employee_id].present?
    data[:remarks] = params[:remarks] if params[:remarks].present?
    Movement.create!(data)
  end


  def move(params)
    mutex = Mutex.new
    # XXX does not work now
    puts params
    puts '----------------------------------------------------------------------'
    type = MoveType.find_by!(typeId: 'MOVE')

    toWh = Whouse.find_by(id: params[:toWh])
    raise "目的仓库#{toWh}未找到" unless toWh
    # validate_position(toWh, params[:toPosition])
    move_data = {to_id: toWh.id, toPosition: params[:toPosition], type_id: type.id}
    move_data[:employee_id] = params[:employee_id] if params[:employee_id].present?
    move_data[:remarks] = params[:remarks] if params[:remarks].present?
    move_data[:movement_list_id] = params[:movement_list_id] if params[:movement_list_id].present?

    user_id=params[:user].blank? ? params[:employee_id] : params[:user].id
    PaperTrail.whodunnit = user_id

    mutex.synchronize {
      if params[:uniqueId].present?
        #Move(uniqueId,toWh,toPosition,type)
        # find from wh
        storage = NStorage.find_by(uniqueId: params[:uniqueId])
        raise '包装未入库！' unless storage.blank?

        # update parameters of movement creation
        move_data.update({from_id: storage.ware_house_id, fromPosition: storage.position,
                          uniqueId: params[:uniqueId], qty: storage.qty, fifo: storage.fifo, partRr: storage.partNr})
        # create movement
        Movement.create!(move_data)
        # update storage
        storage.update!(ware_house_id: toWh.id, position: params[:toPosition])
      elsif params[:packageId].present?
        # Move(packageId,partnr, quantity,toWh, toPosition,type)
        # find from wh
        if params[:toPosition].blank?
          raise "目标库位:#{params[:toPosition]}不可空"
        end

        storage = nil
        if params[:partNr].blank?
          if params[:fromWh].present?
            storage = NStorage.find_by(packageId: params[:packageId], ware_house_id: params[:fromWh])
          else
            storage = NStorage.find_by(packageId: params[:packageId])
            params[:fromWh] = storage.ware_house_id if storage
          end
          params[:partNr]=storage.partNr if storage
        else
          if params[:fromWh].present?
            storage = NStorage.find_by(packageId: params[:packageId], partNr: params[:partNr], ware_house_id: params[:fromWh])
          else
            storage = NStorage.find_by(packageId: params[:packageId], partNr: params[:partNr])
            params[:fromWh] = storage.ware_house_id if storage
          end
        end

        puts "############{storage.to_json}"
        raise "源仓库#{params[:fromWh]}不存在该唯一码#{params[:packageId]}！" if storage.nil? || storage.qty < 0
        if params[:qty].blank?
          params[:qty]=storage.qty
        end
        raise '移库数量为 0 ！' if params[:qty].to_i <= 0

        puts "#{storage.qty}:#{params[:qty]}"

        if params[:qty].to_f > storage.qty
          raise "移库量大于剩余量,唯一码#{params[:packageId]}"
        elsif params[:qty].to_f == storage.qty
          storage.update!(ware_house_id: toWh.id, position: params[:toPosition], created_at: Time.now)
          move_data[:qty] = storage.qty
          move_data[:from_id] = params[:fromWh]
          move_data[:partNr] = storage.partNr
          move_data[:fromPosition] = params[:fromPosition]
          move_data[:packageId] = params[:packageId]
          Movement.create!(move_data)
        else
          tostorage = NStorage.where(ware_house_id: toWh.id, partNr: params[:partNr], position: params[:toPosition], packageId: params[:packageId]).order("n_storages.qty asc").first

          if tostorage.blank?
            #create n_storage remarks
            storage_remarks = "#{Time.now.localtime}从包装箱#{params[:packageId]}中移库#{params[:qty]}"
            data = {partNr: params[:partNr], qty: params[:qty], fifo: storage.fifo, ware_house_id: toWh.id, position: params[:toPosition], remarks: storage_remarks}
            NStorage.create!(data)
          else
            if (tostorage.qty.to_f + params[:qty].to_f) == 0
              tostorage.destroy!
            else
              storage_remarks = "#{Time.now.localtime}从包装箱#{params[:packageId]}中移库#{params[:qty]}"
              tostorage.update!(remarks: storage_remarks, qty: tostorage.qty + params[:qty].to_f)
            end
          end

          storage.update!(qty: storage.qty - params[:qty].to_f)
          move_data[:qty] = params[:qty]
          move_data[:from_id] = params[:fromWh]
          move_data[:partNr] = storage.partNr
          move_data[:fromPosition] = params[:fromPosition]
          move_data[:packageId] = params[:packageId]
          Movement.create!(move_data)
        end

      elsif [:partNr, :qty].reduce(true) { |seed, i| seed and params.include? i }

        if params[:toPosition].blank?
          raise "目标库位:#{params[:toPosition]}不可空"
        end

        # Move(partNr, qty, fromWh,fromPosition,toWh,toPosition,type)
        # Move(partNr, qty, fifo,fromWh,fromPosition,toWh,toPosition,type)
        fromWh = Whouse.find_by(id: params[:fromWh])
        raise "源仓库:#{fromWh}未找到" unless fromWh

        #raise "移库数量必须大于零" if  params[:qty].to_f < 0
        #validate_position(fromWh, params[:fromPosition])
        # find storage records
        if params[:fromPosition].present?
          storages = NStorage.where(partNr: params[:partNr], ware_house_id: fromWh.id, position: params[:fromPosition]).where("n_storages.qty > ?", 0).order(fifo: :asc)
        else
          storages = NStorage.where(partNr: params[:partNr], ware_house_id: fromWh.id).where("n_storages.qty > ?", 0).order(fifo: :asc)
        end
        #   if params[:fromPosition].present?
        #   negatives_storages = NStorage.where(partNr: params[:partNr], ware_house_id: fromWh.id, position: params[:fromPosition]).where("n_storages.qty < ?", 0)
        #   else
        #   negatives_storages = NStorage.where(partNr: params[:partNr], ware_house_id: fromWh.id).where("n_storages.qty < ?", 0)
        # end

        # add fifo condition if fifo param exists
        if params[:fifo]
          fifo = validate_fifo_time(params[:fifo])
          storages.where(fifo: fifo)
        end

        # validate sum of storage qty is enough
        #支持负库存#raise 'No enough qty in source' if sumqty = storages.reduce(0) { |seed, s| seed + s.qty } < params[:qty]
        lastqty = params[:qty].to_f

        if storages.present?

          storages.reduce(params[:qty].to_f) do |restqty, storage|

            break if restqty <= 0

            tostorage = NStorage.where(ware_house_id: toWh.id, partNr: params[:partNr], position: params[:toPosition]).order("n_storages.qty asc").first
            # update parameters of movement creation
            move_data.update({from_id: storage.ware_house_id, fromPosition: storage.position,
                              fifo: storage.fifo, partNr: storage.partNr, remarks: ''})

            if restqty.to_f >= storage.qty.to_f

              move_data[:qty] = storage.qty
              lastqty = restqty = restqty.to_f - storage.qty.to_f

              # move all storage
              if !tostorage.nil?
                if (tostorage.qty.to_f + storage.qty.to_f) == 0
                  tostorage.destroy!
                else
                  if storage.packageId.blank?
                    tostorage.update!(qty: tostorage.qty + storage.qty)
                  else
                    move_data[:remarks] = "#{Time.now.localtime}从包装箱#{storage.packageId}中移库#{storage.qty}"
                    storage_remarks = "#{Time.now.localtime}从包装箱#{storage.packageId}中移库#{storage.qty}"
                    tostorage.update!(remarks: storage_remarks, qty: tostorage.qty + storage.qty)
                  end
                end
                storage.destroy!
              else

                storage.update!(ware_house_id: toWh.id, position: params[:toPosition])
              end
            else

              move_data[:qty] = restqty
              # adjust source storage
              storage.update!(qty: storage.qty - restqty)
              # create target storage
              if !tostorage.nil?
                if (tostorage.qty.to_f + restqty.to_f) == 0
                  tostorage.destroy!
                else
                  if storage.packageId.blank?
                    tostorage.update!(qty: tostorage.qty + restqty)
                  else
                    move_data[:remarks] = "#{Time.now.localtime}从包装箱#{storage.packageId}中移库#{restqty}"
                    storage_remarks = "#{Time.now.localtime}从包装箱#{storage.packageId}中移库#{restqty}"
                    tostorage.update!(remarks: storage_remarks, qty: tostorage.qty + restqty)
                  end
                end
              else
                data = {partNr: storage.partNr, qty: restqty, fifo: storage.fifo, ware_house_id: toWh.id,
                        position: params[:toPosition]}
                move_data[:remarks] = data[:remarks]="#{Time.now.localtime}从包装箱#{storage.packageId}中移库#{restqty}---" if !storage.packageId.blank?
                NStorage.create!(data)
              end

              lastqty = restqty = 0
            end

            # create movement
            Movement.create!(move_data)
            restqty
          end

        end

        #negatives storage default position
        default_position = ""
        if params[:fromPosition].blank?
          if storages.blank?
            default_position = Part.find_by_id(params[:partNr]).default_position(fromWh.id)
          else
            default_position = storages.last.position
          end
        end

        if lastqty > 0
          #src
          # negatives_storages = NStorage.where(partNr: params[:partNr], ware_house_id: fromWh.id, position: params[:fromPosition])

          if params[:fromPosition].present?
            negatives_storage = NStorage.where(partNr: params[:partNr], ware_house_id: fromWh.id, position: params[:fromPosition]).where("n_storages.qty < ?", 0).first
          else
            negatives_storage = NStorage.where(partNr: params[:partNr], ware_house_id: fromWh.id).where("n_storages.qty < ?", 0).first
          end

          if !negatives_storage.blank?
            negatives_storage.update!(qty: negatives_storage.qty - lastqty)
          else
            data = {partNr: params[:partNr], qty: -lastqty, ware_house_id: fromWh.id, position: (params[:fromPosition].blank? ? default_position : params[:fromPosition])}
            puts data
            NStorage.create!(data)
          end

          #dse
          tostorage = NStorage.where(ware_house_id: toWh.id, partNr: params[:partNr], position: params[:toPosition]).order("n_storages.qty asc").first
          if !tostorage.blank?
            if (tostorage.qty.to_f + lastqty.to_f) == 0
              tostorage.destroy!
            else
              tostorage.update!(qty: tostorage.qty + lastqty)
            end
          else
            data = {partNr: params[:partNr], qty: lastqty, ware_house_id: toWh.id, position: params[:toPosition]}
            NStorage.create!(data)
          end

          #movement
          remark = "系统添加备注信息：#{Time.now} 负库存产生【操作员：#{user_id} -- 初始移库数量：#{params[:qty]}】"
          move_data.update({from_id: params[:fromWh], fromPosition: params[:fromPosition], partNr: params[:partNr], qty: lastqty, remark: remark})
          Movement.create!(move_data)

        end

      end
    }
    {result: 1, content: 'move success'}

  end

end
