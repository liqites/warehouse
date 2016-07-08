class DeliveryService
  def self.dispatch(movable, destination, user)
    if movable.descendants.count == 0
      return Message.new.set_false("无法发运空运单")
    end

    ActiveRecord::Base.transaction do
      unless (m = movable.get_movable_service.dispatch(movable, destination, user)).result
        return m
      end

      movable.descendants.each { |d|
        unless (m = d.get_movable_service.dispatch(d, destination, user)).result
          return m
        end
      }

      return Message.new.set_true
    end
  end

  def self.receive(movable, user)
    ActiveRecord::Base.transaction do
      unless (m = movable.get_movable_service.receive(movable, user)).result
        return m
      end

      movable.descendants.each { |d|
        unless (m = d.get_movable_service.receive(d, user)).result
          return m
        end
      }
      return Message.new.set_true
    end
  end

  #兼容以前的接口
  def self.confirm_receive movable, user
    ActiveRecord::Base.transaction do

      unless (m = movable.get_movable_service.check(movable, user)).result
        return m
      end

      #设置forklift的状态
      movable.children.each { |c|
        unless (m = ForkliftService.confirm_receive(c, user)).result
          return m
        end
      }
      return Message.new.set_true
    end
  end

  def self.create args, user
    msg=Message.new
    ActiveRecord::Base.transaction do
      delivery=Delivery.new(remark: args[:remark], user_id: user.id, location_id: user.location_id)
      if delivery.save
        lc=delivery.logistics_containers.build(source_location_id: user.location_id, user_id: user.id, remark: args[:remark])
        # lc.destinationable=user.location.destination
        # lc.des_location_id=user.location.destination.id

        lc.save
        msg.result=true
        msg.object = lc
      else
        msg.content = delivery.errors.full_messages
      end
    end
    msg
  end

  def self.get_list(conditions)
    LogisticsContainer.joins(:delivery).where(conditions).order(created_at: :desc)
  end

  def self.search(condition, controlled=false, location=nil)
    q= if condition && condition['records.impl_time']
         LogisticsContainer.joins(:delivery).joins(:records).where(condition)
       else
         LogisticsContainer.joins(:delivery).where(condition)
       end

    if controlled && location
      q=q.where('des_location_id=? or source_location_id=?', location.id, location.id)
    end
    q.distinct
  end

  def self.import_by_file path
    msg=Message.new
    begin
      ActiveRecord::Base.transaction do
        Sync::Config.skip_muti_callbacks([Container, LogisticsContainer, Record])
        data=JSON.parse(IO.read(path))

        msg.result =true
        [Container, LogisticsContainer, Record].each do |m|
          data[m.name.tableize].each do |c|
            citmp=m.new(c)
            if ci=m.find_by_id(c['id'])
              if ci.updated_at<=citmp.updated_at
                attr=ci.gen_sync_attr(citmp)
                ci.update(attr)
              end
            else
              citmp.save
            end
          end
        end
      end
      msg.result=true
      msg.content='处理成功'
    rescue => e
      msg.result =false
      msg.content=e.message
    end
    return msg
  end

  def self.send_by_excel file
    msg=Message.new
    begin
      ActiveRecord::Base.transaction do
        book=Roo::Excelx.new file
        book.default_sheet=book.sheets.first
        return nil if book.cell(2, 1).nil?
        # generate delivery
        user = User.find_by_id(book.cell(2, 1))

        unless user
          raise 'User not found!'
        end
        # generate delivery container
        source = Location.find_by_id(book.cell(2, 2))

        unless source
          raise 'Destination not found!'
        end

        delivery = Delivery.create({
                                       remark: book.cell(2, 5),
                                       user_id: user.id,
                                       location_id: source.id
                                   })

        # generate delivery location_container
        destination = Location.find_by_id(book.cell(2, 3))

        unless destination
          raise 'Destination not found!'
        end
        dlc = delivery.logistics_containers.build(source_location_id: source.id, des_location_id: destination.id, user_id: user.id, remark: book.cell(2, 5), state: MovableState::WAY)
        dlc.destinationable = destination
        dlc.save
        # send dlc,create record for dlc
        impl_time = Time.parse(book.cell(2, 4))
        Record.create({recordable: dlc, destiationable: dlc.destinationable, impl_id: user.id, impl_user_type: ImplUserType::SENDER, impl_action: 'dispatch', impl_time: impl_time})
        # generate forklifts containers
        forklifts={}
        book.default_sheet=book.sheets[1]
        return nil if book.cell(2, 1).nil?

        2.upto(book.last_row) do |row|
          whouse= Whouse.find_by_id(book.cell(row, 1))
          unless whouse
            raise 'Warehouse not found!'
          end
=begin
          forklift=Forklift.new(state: ForkliftState::WAY,
                                user_id: delivery.user_id,
                                stocker_id: delivery.user_id,
                                whouse_id: Whouse.find_by_id(whouse).id)
          delivery.forklifts<<forklift
=end
          forklift = Forklift.create({
                                         user_id: user.id,
                                         location_id: source.id
                                     })
          #create forklift lc
          flc = forklift.logistics_containers.build({source_location_id: source.id, des_location_id: destination.id, user_id: user.id, state: MovableState::WAY})
          flc.destinationable = whouse
          flc.save
          #impl_time = Time.parse(book.cell(2, 4))
          Record.create({recordable: flc, destiationable: flc.destinationable, impl_id: user.id, impl_user_type: ImplUserType::SENDER, impl_action: 'dispatch', impl_time: impl_time})

          dlc.add(flc)

          forklifts[whouse.id]=flc
        end
        # generate packages
        book.default_sheet=book.sheets[2]
        return nil if book.cell(2, 1).nil?
        2.upto(book.last_row) do |row|
          if plc = LogisticsContainer.find_latest_by_container_id(book.cell(row, 2))
            #if found and can copy
            forklifts[book.cell(row, 1)].add(plc)
          else
            #create container
            package = Package.create({
                                         user_id: user.id,
                                         location_id: source.id
                                     })
            #create lc
            #*王松修改了package check_in_time之后，需要重新写
            plc = package.logistics_containers.build({
                                                         source_location_id: source.id,
                                                         des_location_id: destination.id,
                                                         user_id: user.id,
                                                         state: MovableState::WAY,
                                                         part_id: bool.cell(row, 3).sub(/P/, ''),
                                                         quantity: bool.cell(row, 4).sub(/Q/, ''),
                                                         check_in_time: book.cell(row, 5).sub(/W\s*/, '')
                                                     })
            plc.destinationable = PartService.get_position_by_whouse_id(op.part_id, flc.destinationable_id)
            plc.save
            #impl_time = Time.parse(book.cell(2, 4))
            Record.create({recordable: plc, destiationable: plc.destinationable, impl_id: user.id, impl_user_type: ImplUserType::SENDER, impl_action: 'dispatch', impl_time: impl_time})
            forklifts[book.cell(row, 1)].add(plc)
          end

=begin
          if package=Package.find_by_id(book.cell(row, 2))
            forklifts[book.cell(row, 1)].packages<<package
          else
            forklifts[book.cell(row, 1)].packages<<Package.new(id: book.cell(row, 2),
                                                               location_id: delivery.source_id,
                                                               user_id: delivery.user_id,
                                                               part_id: book.cell(row, 3).sub(/P/, ''),
                                                               quantity: book.cell(row, 4).sub(/Q/, ''),
                                                               quantity_str: book.cell(row, 4).sub(/Q/, ''),
                                                               check_in_time: book.cell(row, 5).sub(/W\s*/, ''),
                                                               state: PackageState::WAY
            )
          end
=end
        end

        #delivery.save
=begin
        forklifts.values.each do |forklift|
          forklift.update(sum_packages: forklift.packages.count)
        end
=end
        msg.content ='处理成功'
        msg.result =true
      end
    rescue => e
      msg.result=false
      msg.content = e.message
    end
    return msg
  end

  def self.receive_by_excel file
    msg=Message.new
    begin
      ActiveRecord::Base.transaction do
        book=Roo::Excelx.new file
        book.default_sheet=book.sheets.first
        return nil if book.cell(2, 1).nil?

        default_receiver = User.where({role_id: Role.sender}).first

        2.upto(book.last_row) do |row|
          if plc = LogisticsContainer.find_latest_by_container_id(book.cell(2, 1))
            plc.get_movable_service.receive(plc, default_receiver)

            if flc = plc.parent
              flc.get_movable_service.receive(flc, default_receiver)

              if dlc = flc.parent
                dlc.get_movable_service.receive(dlc, default_receiver)
              end
            end
          end

        end
      end
      msg.result =true
      msg.content = '处理成功'
    rescue => e
      msg.result=false
      msg.content = e.message
    end
    return msg
  end


  def self.enter_stock user, lc, warehouse, position, fifo
    raise '禁止以运单入库'
  end

  def self.to_xlsx deliveries
    p = Axlsx::Package.new

    wb = p.workbook
    wb.add_worksheet(:name => "sheet1") do |sheet|
      sheet.add_row [
                        "序号", "收发货日期", "收发货", "发送地", "接收地", "票数", "装箱单号", "运单号",
                        "托盘号", "包装箱号", "零件号", "数量", "零件类型", "包装类型", "备注"
                    ]

      count=0
      action=''
      deliveries.each_with_index do |delivery, index|
        p delivery
        forklifts=LogisticsContainerService.get_forklifts(delivery)
        forklifts.each do |forklift|
          if delivery.source_location.id==Location.find_by_nr('JXJX').id
            action='收货'
          else
            action='发货'
          end

          packages=LogisticsContainerService.get_packages(forklift)
          packages.each do |package|
            part=Part.find_by_id(package.package.part_id)
            count+=1
            sheet.add_row [
                              count,
                              package.package.fifo_time.blank? ? '' : package.package.fifo_time.localtime.strftime('%y.%m.%d %H:%M'),
                              action,
                              delivery.source_location.name,
                              delivery.destination.name,
                              index+1,
                              delivery.delivery.extra_batch,
                              delivery.container_id,
                              forklift.container_id.to_s,
                              package.package.id.to_s,
                              part.blank? ? '' : part.nr.to_s,
                              package.package.quantity.to_s,
                              part.blank? ? '' : part.type_name,
                              part.blank? ? '' : part.package_name,
                              package.remark
                          ], types: [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
          end
        end


      end


    end

    p.to_stream.read
  end

  def self.delete id
    puts "--------------------#{id}---------------------------"
    d=Container.find_by_id(id)
    if d && (d.state != DeliveryState::RECEIVED)
      d.update_attributes(is_delete: true)
      dlc=d.logistics_containers.first
      if move_list=MovementList.find_by_id(d.movement_list_id)
        move_list.destroy
      end

      fs=LogisticsContainerService.get_forklifts(dlc)
      fs.each do |f|
        f.forklift.update_attributes(is_delete: true)

        ps=LogisticsContainerService.get_packages(f)
        ps.each do |p|
          p.package.update_attributes(is_delete: true)
          p.update_attributes(is_delete: true)
        end
      end

    else
      raise "未找到该运单号或者该运单已出入库，不可删除"
    end
  end

  def self.stock_move id
    msg=Message.new

    begin
      LogisticsContainer.transaction do
        dlc=LogisticsContainer.find_by_id(id)
        if dlc && (dlc.state == MovableState::ARRIVED)
          d=dlc.delivery
          d.update_attributes(state: DeliveryState::RECEIVED)
          dlc.update_attributes(state: MovableState::CHECKED)

          fs=LogisticsContainerService.get_forklifts(dlc)
          fs.each do |f|
            f.update_attributes(state: MovableState::CHECKED)
            f.forklift.update_attributes(state: ForkliftState::RECEIVED)

            ps=LogisticsContainerService.get_packages(f)
            ps.each do |p|
              p.update_attributes(state: MovableState::CHECKED)
              p.package.update_attributes(state: PackageState::RECEIVED)

              whouse=Whouse.find_by_id(p.package.extra_whouse_id)
              position=Position.find_by_id(p.package.extra_position_id)

              if dlc.source_location.id==(Location.find_by_nr('JXJX').id)
                #stock move
                p.move_stock(dlc.des_location, whouse, position, p.package.extra_fifo, d.movement_list_id, false)
                #Container move
                mmsg=WrappageService.move_wrappage(p, dlc.source_location, dlc.des_location)
                # unless mmsg.result
                #   raise mmsg.content
                #   # msg.content = mmsg.content
                #   # return msg
                # end
                msg.content = "运单出库成功"
              else
                #stock enter
                p.enter_stock(whouse, position, p.package.extra_fifo, d.movement_list_id, false)
                msg.content = "运单入库成功"
              end

            end
          end
          msg.result=true
        else
          msg.content = "未找到该运单号或者该运单已出入库"
        end
      end
    rescue => e
      msg.result=false
      msg.content = e.message
    end

    msg
  end

end
