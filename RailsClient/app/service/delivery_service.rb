class DeliveryService

  def self.create args, user
    msg=Message.new
    ActiveRecord::Base.transaction do
      delivery=Delivery.new(remark: args[:remark], user_id: user.id, location_id: user.location_id)
      if delivery.save
        lc=delivery.logistics_containers.build(source_location_id: user.location_id, user_id: user.id,remark:args[:remark])
        lc.destinationable=user.location.destination
        lc.des_location_id=user.location.destination.id

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


  def self.import_by_file path
    msg=Message.new
    begin
      ActiveRecord::Base.transaction do
        Sync::Config.skip_muti_callbacks([Delivery, Forklift, Package, PackagePosition, StateLog])
        data=JSON.parse(IO.read(path))
        msg.result =true # unless Delivery.find_by_id(data['delivery']['id'])
        if dori=Delivery.find_by_id(data['delivery']['id'])
          dtmp=Delivery.new(data['delivery'])
          if dori.updated_at<=dtmp.updated_at
            attr=dori.gen_sync_attr(dtmp)
            dori.update(attr)
          end
        else
          Delivery.create(data['delivery'])
        end
        data['forklifts'].each do |forklift|
          if fori=Forklift.find_by_id(forklift['id'])
            ftmp=Forklift.new(forklift)
            if fori.updated_at<=ftmp.updated_at
              attr=fori.gen_sync_attr(ftmp)
              fori.update(attr)
            end
          else
            Forklift.create(forklift)
          end
        end

        data['packages'].each do |package|
          if pori=Package.find_by_id(package['id'])
            ptmp=Package.new(package)
            if pori.updated_at<=ptmp.updated_at
              attr=pori.gen_sync_attr(ptmp)
              pori.update(attr)
            end
          else
            Package.create(package)
          end
        end

        PackagePosition.create(data['package_positions'].select { |pp| !pp.nil? })
        #StateLog.create(data['state_logs'])
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
        delivery=Delivery.new(state: DeliveryState::WAY,
                              user_id: book.cell(2, 1),
                              source_id: book.cell(2, 2),
                              destination_id: book.cell(2, 3),
                              delivery_date: book.cell(2, 4),
                              remark: book.cell(2, 5))
        # generate forklifts
        forklifts={}
        book.default_sheet=book.sheets[1]
        return nil if book.cell(2, 1).nil?

        2.upto(book.last_row) do |row|
          whouse=book.cell(row, 1)
          forklift=Forklift.new(state: ForkliftState::WAY,
                                user_id: delivery.user_id,
                                stocker_id: delivery.user_id,
                                whouse_id: Whouse.find_by_id(whouse).id)
          delivery.forklifts<<forklift
          forklifts[whouse]=forklift
        end
        # generate packages
        book.default_sheet=book.sheets[2]
        return nil if book.cell(2, 1).nil?
        2.upto(book.last_row) do |row|
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
        end

        delivery.save
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
        2.upto(book.last_row) do |row|
          if package=Package.find_by_id(book.cell(row, 1))
            package.update(state: PackageState::RECEIVED, is_dirty: true)
            if  forklift=package.forklift
              forklift.update(state: ForkliftState::RECEIVED, is_dirty: true)
              if delivery= forklift.delivery
                delivery.update(state: DeliveryState::RECEIVED, is_dirty: true)
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
end
