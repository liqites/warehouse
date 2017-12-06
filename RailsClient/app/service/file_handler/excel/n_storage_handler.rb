module FileHandler
  module Excel
    class NStorageHandler<Base

      IMPORT_HEADERS=[
          :toWh, :partNr, :fifo, :qty, :toPosition, :employee_id, :remarks
      ]

      #after change do not forget change 'validate_move', too
      MOVE_HEADERS = [
          :fromWh, :fromPosition, :partNr, :qty, :fifo, :toWh, :toPosition, :employee_id, :remarks
      ]

      def self.import(file, current_user)
        msg = Message.new
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        validate_msg = validate_import(file)
        if validate_msg.result
          begin
            NStorage.transaction do
              move_list = MovementList.create(builder: current_user.id, name: "#{current_user.nr}_#{DateTime.now.strftime("%H.%d.%m.%Y")}_F")
              2.upto(book.last_row) do |line|
                row = {}
                IMPORT_HEADERS.each_with_index do |k, i|
                  row[k] = book.cell(line, i+1).to_s.strip
                  if k== :partNr || k==:employee_id
                    row[k] = row[k].sub(/\.0/, '')
                  end
                end

                if part=Part.find_by_nr(row[:partNr])
                  row[:partNr]=part.id
                end
                if toWh=Whouse.find_by_nr(row[:toWh])
                  row[:toWh]=toWh.id
                end
                if toPosition=Position.find_by_nr(row[:toPosition])
                  row[:toPosition]=toPosition.id
                end
                if employee=User.find_by_id(row[:employee_id])
                  row[:employee_id]=employee.id
                end

                row[:movement_list_id] = move_list.id
                MovementSource.create(row)

                row[:user] = current_user
                WhouseService.new.enter_stock(row)
                move_list.update(state: MovementListState::ENDING)
              end
            end
            msg.result = true
            msg.content = "导入库存数据成功"
          rescue => e
            puts e.backtrace
            msg.result = false
            msg.content = e.message
          end
        else
          msg.result = false
          msg.content = validate_msg.content
        end

        msg
      end

      def self.move(file, current_user)
        msg = Message.new
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first
        validate_msg = validate_move(file)
        if validate_msg.result
          begin
            NStorage.transaction do
              move_list = MovementList.create(builder: current_user.id, name: "#{current_user.nr}_#{DateTime.now.strftime("%H.%d.%m.%Y")}_File")
              2.upto(book.last_row) do |line|
                row = {}
                MOVE_HEADERS.each_with_index do |k, i|
                  row[k] = book.cell(line, i+1).to_s.strip
                  if k== :partNr || k== :packageId
                    row[k] = row[k].sub(/\.0/, '')
                  end
                end

                if part=Part.find_by_nr(row[:partNr])
                  row[:partNr]=part.id
                end
                if toWh=Whouse.find_by_nr(row[:toWh])
                  row[:toWh]=toWh.id
                end
                if toPosition=Position.find_by_nr(row[:toPosition])
                  row[:toPosition]=toPosition.id
                end
                if employee=User.find_by_id(row[:employee_id])
                  row[:employee_id]=employee.id
                end
                if fromWh=Whouse.find_by_nr(row[:fromWh])
                  row[:fromWh]=fromWh.id
                end
                if fromPosition=Position.find_by_nr(row[:fromPosition])
                  row[:fromPosition]=fromPosition.id
                end

                # if package = NStorage.exists_package?(row[:packageId])
                #   row[:qty]=package.qty
                # end

                unless row[:employee_id].present?
                  row[:employee_id]=current_user.nr
                end

                row[:movement_list_id] = move_list.id
                MovementSource.create(row)

                row[:user] = current_user
                WhouseService.new.move(row)
                move_list.update(state: MovementListState::ENDING)
              end
            end
            msg.result = true
            msg.content = "导入移库数据成功"
          rescue => e
            puts e.backtrace
            msg.result = false
            msg.content = e.message
          end
        else
          msg.result = false
          msg.content = validate_msg.content
        end

        msg
      end

      def self.validate_import file
        tmp_file=full_tmp_path(file.oriName)
        msg = Message.new(result: true)
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        p = Axlsx::Package.new
        p.workbook.add_worksheet(:name => "Basic Worksheet") do |sheet|
          sheet.add_row IMPORT_HEADERS+['Error Msg']
          #validate file
          2.upto(book.last_row) do |line|
            row = {}
            IMPORT_HEADERS.each_with_index do |k, i|
              row[k] = book.cell(line, i+1).to_s.strip
              row[k]=row[k].sub(/\.0/, '') if k== :partNr
            end

            mssg = validate_import_row(row, line)
            if mssg.result
              sheet.add_row row.values
            else
              if msg.result
                msg.result = false
                msg.content = "下载错误文件<a href='/files/#{Base64.urlsafe_encode64(tmp_file)}'>#{::File.basename(tmp_file)}</a>"
              end
              sheet.add_row row.values<<mssg.content
            end
          end
        end
        p.use_shared_strings = true
        p.serialize(tmp_file)
        msg
      end

      def self.validate_import_row(row, line)
        msg = Message.new(contents: [])
        # StorageOperationRecord.save_record(row, 'ENTRY')

        if row[:toWh].blank?
          msg.contents << "目的仓库号不可为空!"
        else
          src_warehouse = Whouse.find_by_nr(row[:toWh])
          unless src_warehouse
            msg.contents << "目的仓库号:#{row[:toWh]} 不存在!"
          end
        end

        if row[:partNr].blank?
          msg.contents << "零件号不可为空!"
        else
          part = Part.find_by_nr(row[:partNr])
          unless part
            msg.contents << "零件号:#{row[:partNr]} 不存在!"
          end
        end

        if row[:qty].blank? || row[:qty].to_f <= 0
          msg.contents << "数量: #{row[:qty]} 不可以小于等于 0!"
        end

        if row[:fifo].present?
          begin
            row[:fifo].to_time
          rescue => e
            msg.contents << "FIFO: #{row[:fifo]} 错误!"
          end
        end

        if row[:toPosition].blank?
          msg.contents << "目的库位号不可为空!"
        else
          position = Position.find_by(nr: row[:toPosition])
          unless position
            msg.contents << "目的库位号:#{row[:toPosition]} 不存在!"
          end
        end

        if row[:employee_id].blank?
          msg.contents << "员工号不可为空!"
        else
          employee = User.find_by_nr(row[:employee_id])
          unless employee
            msg.contents << "员工号:#{row[:employee_id].sub(/\.0/, '')} 不存在!"
          end
        end

        unless msg.result=(msg.contents.size==0)
          msg.content=msg.contents.join('/')
        end
        msg
      end

      def self.validate_move file
        tmp_file=full_tmp_path(file.oriName)
        msg = Message.new(result: true)
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        ##########################################################################
        #will store position stock
        position_stock={}
        2.upto(book.last_row) do |line|
          if position_stock[book.cell(line, 7).to_s.strip].blank?
            position_stock[book.cell(line, 7).to_s.strip] = 1
          else
            position_stock[book.cell(line, 7).to_s.strip] += 1
          end
        end
        nomal_position_capacity=SysConfigCache.nomal_position_capacity_value
        wooden_position_capacity=SysConfigCache.wooden_position_capacity_value
        wooden_position=SysConfigCache.wooden_position_config_value

        p = Axlsx::Package.new
        p.workbook.add_worksheet(:name => "Basic Worksheet") do |sheet|
          sheet.add_row MOVE_HEADERS+['Error Msg', 'Overload Msg']
          #validate file
          2.upto(book.last_row) do |line|
            row = {}
            MOVE_HEADERS.each_with_index do |k, i|
              row[k] = book.cell(line, i+1).to_s.strip
              row[k]=row[k].sub(/\.0/, '') if k== :partNr || k== :packageId
            end

            mssg = validate_move_row(row)
            # if mssg.result
            #   sheet.add_row row.values
            # else
            #   if msg.result
            #     msg.result = false
            #     msg.content = "下载错误文件<a href='/files/#{Base64.urlsafe_encode64(tmp_file)}'>#{::File.basename(tmp_file)}</a>"
            #   end
            #   sheet.add_row row.values<<mssg.content
            # end

            ########################################################################
            #check position capacity
            tmp_file_row=row.values
            if mssg.result
              tmp_file_row<<' '
            else
              if msg.result
                msg.result = false
                msg.content = "下载错误文件<a href='/files/#{Base64.urlsafe_encode64(tmp_file)}'>#{::File.basename(tmp_file)}</a>"
              end
              tmp_file_row<<mssg.content
            end

            if position=Position.find_by_nr(row[:toPosition])
              if position.nr==wooden_position
                position_capacity=wooden_position_capacity
              else
                position_capacity=nomal_position_capacity
              end

              if SysConfigCache.position_capacity_switch_value=='true'
                result=position.check_position_capacity(position_stock[row[:toPosition]], position_capacity.to_i)
              else
                result = Message.new(result: true)
              end

              if !result.result && msg.result
                msg.result = false
                msg.content = "下载错误文件<a href='/files/#{Base64.urlsafe_encode64(tmp_file)}'>#{::File.basename(tmp_file)}</a>"
              end
              tmp_file_row<<result.content
            end

            sheet.add_row tmp_file_row

          end
        end
        p.use_shared_strings = true
        p.serialize(tmp_file)
        msg
      end

      def self.validate_move_row(row)
        msg = Message.new(contents: [])
        # StorageOperationRecord.save_record(row, 'MOVE')

        if row[:toWh].blank?
          msg.contents << "目的仓库号不能为空!"
        else
          dse_warehouse = Whouse.find_by_nr(row[:toWh])
          unless dse_warehouse
            msg.contents << "目的仓库号:#{row[:toWh]} 不存在!"
          end
        end

        if row[:toPosition].blank?
          msg.contents << "目的库位号不能为空!"
        else
          to_position = Position.find_by_nr(row[:toPosition])
          unless to_position
            msg.contents << "目的库位号:#{row[:toPosition]} 不存在!"
          end
        end

        if row[:fromWh].blank?
          msg.contents << "源仓库号不能为空!"
        else
          src_warehouse = Whouse.find_by_nr(row[:fromWh])
          unless src_warehouse
            msg.contents << "源仓库号:#{row[:fromWh]} 不存在!"
          end
        end

        if row[:fromPosition].present?
          from_position = Position.find_by_nr(row[:fromPosition])
          unless from_position
            msg.contents << "源位置:#{row[:fromPosition]} 不存在!"
          end
        end

        positions = []
        if row[:partNr].blank?
          msg.contents << "零件号不能为空!"
        else
          part = Part.find_by_nr(row[:partNr])
          if part
            part.positions.each do |position|
              positions += ["#{position.nr}"]
            end
          else
            msg.contents << "零件号:#{row[:partNr]} 不存在!"
          end
        end

        if row[:fifo].present?
          begin
            row[:fifo].to_time
          rescue => e
            msg.contents << "FIFO: #{row[:fifo]} 错误!"
          end
        end

        if row[:qty].blank? || row[:qty].to_f <= 0
          msg.contents << "数量: #{row[:qty]} 不可以小于等于 0!"
        end


        unless msg.result=(msg.contents.size==0)
          msg.content=msg.contents.join('/')
        end
        msg
      end


    end
  end
end
