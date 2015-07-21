module FileHandler
  module Excel
    class NStorageHandler<Base

      IMPORT_HEADERS=[
          :toWh,:partNr,:fifo,:qty,:toPosition,:packageId, :employee_id, :remarks
      ]

      MOVE_HEADS = [
          :fromWh, :fromPosition, :packageId, :partNr, :qty, :fifo, :toWh, :toPosition, :employee_id, :remarks
      ]

      def self.import(file)
        msg = Message.new
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        validate_msg = validate_import(file)
        if validate_msg.result
          begin
            NStorage.transaction do
              2.upto(book.last_row) do |line|
                row = {}
                IMPORT_HEADERS.each_with_index do |k, i|
                  row[k] = book.cell(line, i+1).to_s.strip
                  if k== :partNr || k== :packageId
                    row[k] = row[k].sub(/\.0/, '')
                  end
                end

                WhouseService.new.enter_stock(row)

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

      def self.move(file)
        msg = Message.new
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        validate_msg = validate_move(file)
        if validate_msg.result
          begin
            NStorage.transaction do
              2.upto(book.last_row) do |line|
                row = {}
                MOVE_HEADS.each_with_index do |k, i|
                  row[k] = book.cell(line, i+1).to_s.strip
                  if k== :partNr || k== :packageId
                    row[k] = row[k].sub(/\.0/, '')
                  end
                end

                WhouseService.new.move(row)

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
              row[k]=row[k].sub(/\.0/, '') if k== :partNr || k== :packageId
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

        src_warehouse = Whouse.find_by_name(row[:toWh])
        unless src_warehouse
          msg.contents << "仓库号:#{row[:toWh]} 不存在!"
        end

        part_id = Part.find_by_id(row[:partNr])
        unless part_id
          msg.contents << "零件号:#{row[:partNr]} 不存在!"
        end

        unless row[:qty].to_f > 0
          msg.contents << "数量: #{row[:qty]} 不可以小于等于 0!"
        end

        if row[:fifo].present?
          begin
            row[:fifo].to_time
          rescue => e
            msg.contents << "FIFO: #{row[:fifo]} 错误!"
          end
        end

        if row[:toPosition].present?
          position = Position.find_by_name(row[:toPosition])
          unless position
            msg.contents << "库位号:#{row[:toPosition]} 不存在!"
          end
        end

        if row[:employee_id].present?
          employee_id = User.find(row[:employee_id])
          unless employee_id
            msg.contents << "员工号:#{row[:employee_id]} 不存在!"
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

        p = Axlsx::Package.new
        p.workbook.add_worksheet(:name => "Basic Worksheet") do |sheet|
          sheet.add_row MOVE_HEADERS+['Error Msg']
          #validate file
          2.upto(book.last_row) do |line|
            row = {}
            MOVE_HEADERS.each_with_index do |k, i|
              row[k] = book.cell(line, i+1).to_s.strip
              row[k]=row[k].sub(/\.0/, '') if k== :partNr || k== :packageId
            end

            mssg = validate_move_row(row, line)
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

      def self.validate_move_row(row, line)
        msg = Message.new(contents: [])

        if row[:fromWh].present?
          src_warehouse = Whouse.find_by_name(row[:fromWh])
          unless src_warehouse
            msg.contents << "源仓库号:#{row[:fromWh]} 不存在!"
          end
        end

        if row[:toWh].present?
          dse_warehouse = Whouse.find_by_name(row[:toWh])
          unless dse_warehouse
            msg.contents << "目的仓库号:#{row[:toWh]} 不存在!"
          end
        end

        part_id = Part.find_by_id(row[:partNr])
        unless part_id
          msg.contents << "零件号:#{row[:partNr]} 不存在!"
        end

        unless row[:qty].to_f > 0
          msg.contents << "数量: #{row[:qty]} 不可以小于等于 0!"
        end

        if row[:fifo].present?
          begin
            row[:fifo].to_time
          rescue => e
            msg.contents << "FIFO: #{row[:fifo]} 错误!"
          end
        end

        if row[:fromPosition].present?
          from_position = Position.find_by_name(row[:fromPosition])
          unless from_position
            msg.contents << "库位号:#{row[:fromPosition]} 不存在!"
          end
        end

        if row[:toPosition].present?
          to_position = Position.find_by_name(row[:toPosition])
          unless to_position
            msg.contents << "库位号:#{row[:toPosition]} 不存在!"
          end
        end

        if row[:employee_id].present?
          employee_id = User.find(row[:employee_id])
          unless employee_id
            msg.contents << "员工号:#{row[:employee_id]} 不存在!"
          end
        end

        unless msg.result=(msg.contents.size==0)
          msg.content=msg.contents.join('/')
        end
        msg
      end


    end
  end
end