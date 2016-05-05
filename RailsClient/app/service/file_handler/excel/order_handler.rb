module FileHandler
  module Excel
    class OrderHandler<Base
      HEADERS=['报缺日期', '报缺时间', '莱尼号码', '桶数', "是否补发"]

      def self.import(file, user)
        msg = Message.new
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        validate_msg=validate_import(file)

        if validate_msg.result
          begin
            Order.transaction do
              order = Order.new()
              order.source_id=user.location.id
              order.remark = "文件导入需求单"
              p '***************************************'
              last_row={}
              HEADERS.each_with_index do |k, i|
                last_row[k] = book.cell(book.last_row, i+1).to_s.strip
                last_row[k]=last_row[k].sub(/\.0/, '') if k=='莱尼号码'
              end
              p last_row
              p "#{last_row['报缺日期'].gsub(/,/, '.')} #{last_row['报缺时间']}"
              p Time.parse("#{last_row['报缺日期'].gsub(/,/, '.')} #{last_row['报缺时间']}")
              p Time.parse("#{last_row['报缺日期'].gsub(/,/, '.')} #{last_row['报缺时间']}").utc
              order.required_at=Time.parse("#{last_row['报缺日期'].gsub(/,/, '.')} #{last_row['报缺时间']}").utc
              p '***************************************'

              if order.save
                pick=PickList.new(state: PickStatus::INIT)
                pick.user=user
                pick.remark="AUTO CREATE BY ORDER"

                part_ids=[]
                records={}
                2.upto(book.last_row) do |line|
                  row = {}
                  HEADERS.each_with_index do |k, i|
                    row[k] = book.cell(line, i+1).to_s.strip
                    row[k]=row[k].sub(/\.0/, '') if k=='莱尼号码'
                  end
                  #batch_nr=row['报缺日期'].gsub(/,/, '') + row['报缺时间'].slice(0...2)

                  part_ids<<row['莱尼号码'].downcase
                  if records[row['莱尼号码'].downcase]
                    records[row['莱尼号码'].downcase][:qty]=records[row['莱尼号码'].downcase][:qty].to_i + row['桶数'].to_i
                  else
                    records[row['莱尼号码'].downcase]={
                        part_id: row['莱尼号码'],
                        qty: row['桶数'],
                        batch_nr: order.batch_nr
                    }
                  end
                end


                part_ids.uniq.each do |id|
                  part=nil
                  if part_client=PartClient.where(client_tenant_id: Tenant.find_by_code('SHL').id, client_part_nr: id).first
                    part = part_client.part
                    # else
                    #   part=Part.new()
                  end

                  order_item=OrderItem.new({
                                               part_id: part.blank? ? id : part.id,
                                               part_type_id: part.blank? ? '' : part.part_type_id,
                                               box_quantity:1,
                                               quantity: records[id.downcase][:qty],
                                               remark: NStorageService.get_remark(part, user.location, records[id.downcase][:qty].to_i)#,
                                               # is_supplement: row['是否补发']=='Y' ? true : false
                                           })
                  order_item.user=user
                  order_item.order = order
                  order_item.location_id=user.location.id
                  order_item.handled=true

                  if order_item.save
                    pick_item=PickItem.new(
                        batch_nr: records[id.downcase][:batch_nr],
                        user_id: user.id,
                        part_id: part.blank? ? id : part.id,
                        quantity: records[id.downcase][:qty],
                        state: PickStatus::INIT,
                        remark: NStorageService.get_remark(part, user.location, records[id.downcase][:qty].to_i)
                    )
                    pick_item.order_item=order_item
                    pick.pick_items<<pick_item
                  end
                end

                pick.order_ids=order.order_items.pluck(:id).join(";")
                pick.save
              end

            end
            msg.result = true
            msg.content = "导入数据成功"
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
          sheet.add_row HEADERS+['Error Msg']

          #validate file
          if book.row(2)[2].blank?
            raise "文件没有数据"
          end

          2.upto(book.last_row) do |line|
            row = {}
            HEADERS.each_with_index do |k, i|
              row[k] = book.cell(line, i+1).to_s.strip
              row[k]=row[k].sub(/\.0/, '') if k=='莱尼号码'
            end

            mssg = validate_row(row)
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

      def self.validate_row(row)
        msg = Message.new(contents: [])

        if row['莱尼号码'].blank?
          msg.contents << "零件号不能为空"
        end

        unless PartClient.where(client_tenant_id: Tenant.find_by_code('SHL').id, client_part_nr: row['莱尼号码']).first
          msg.contents << "零件号不存在"
        end

        if row['报缺日期'].blank?
          msg.contents << "报缺日期不可空"
        end
        if row['报缺时间'].blank?
          msg.contents << "报缺时间不可空"
        end
        if row['莱尼号码'].blank?
          msg.contents << "莱尼号码不可空"
        end
        if row['桶数'].blank?
          msg.contents << "桶数不可空"
        end


        unless msg.result=(msg.contents.size==0)
          msg.content=msg.contents.join('/')
        end
        msg
      end


    end
  end
end
