module FileHandler
  module Excel
    class OrderBoxHandler<Base
      HEADERS=[
          :nr, :rfid_nr, :status, :part_id, :quantity, :whouse_id, :source_whouse_id, :order_box_type_id, :position_id, :operator
      ]

      def self.import(file)
        msg = Message.new
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        validate_msg = validate_import(file)
        if validate_msg.result
          #validate file
          # begin
          OrderBox.transaction do
            2.upto(book.last_row) do |line|
              row = {}
              HEADERS.each_with_index do |k, i|
                row[k] = book.cell(line, i+1).to_s.strip
                if k.to_s=='part_id'
                  row[k]=row[k].sub(/\.0/, '')
                end

              end
              row[:order_box_type_id] = OrderBoxType.find_by_name(row[:order_box_type_id]).id unless row[:order_box_type_id].blank?

              row.delete(:status) if row[:status].blank?
              position=nil
              position=Position.find_by_id(row[:position_id]) unless row[:position_id].blank?

              if ob=OrderBox.find_by_nr(row[:nr])
                if row[:operator].blank? || row[:operator]=='update'
                  ob.position=position if position
                  ob.update(row.except(:nr, :position_id, :operator))
                elsif row[:operator]=='delete'
                  ob.destroy
                end
              else
                if row[:operator].blank? || row[:operator]=='create'
                  s =OrderBox.new(row.except(:position_id, :operator))
                  s.position=position  if position
                  unless s.save
                    puts s.errors.to_json
                    raise s.errors.to_json
                  end
                end
              end

            end
          end
          msg.result = true
          msg.content = "导入料盒信息成功！"
          # rescue => e
          #  puts e.backtrace
          # msg.result = false
          # msg.content = e.message
          # end
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
          sheet.add_row HEADERS+['Error Msg']
          #validate file
          2.upto(book.last_row) do |line|
            row = {}
            HEADERS.each_with_index do |k, i|
              row[k] = book.cell(line, i+1).to_s.strip

              if k.to_s=='part_id'
                row[k]=row[k].sub(/\.0/, '')
              end

            end

            mssg = validate_row(row, line)
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

      def self.validate_row(row, line)
        msg = Message.new(contents: [])

        # if OrderBox.find_by_nr(row[:nr])
        #   msg.contents<<"该料盒已存在"
        # end

        unless Part.find_by_id(row[:part_id])
          msg.contents<<"该零件不存在"
        end

        unless row[:whouse_id].blank?
          unless Whouse.find_by_id(row[:whouse_id])
            msg.contents<<"要货仓库不存在"
          end
        end

        unless row[:source_whouse_id].blank?
          unless Whouse.find_by_id(row[:source_whouse_id])
            msg.contents<<"出货仓库不存在"
          end
        end

        unless row[:order_box_type_id].blank?
          unless OrderBoxType.find_by_name(row[:order_box_type_id])
            msg.contents<<"料盒类型不存在"
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