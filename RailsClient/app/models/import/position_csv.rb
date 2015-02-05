module Import
  module PositionCsv
    def self.included(base)
      base.extend CsvBase
      base.extend ClassMethods
      base.init_csv_cols
      base.init_uniq_key
    end


  end

  module ClassMethods
    #@@csv_cols=nil

    def uniq_key
      class_variable_get(:@@ukeys)
    end

    def csv_headers
      class_variable_get(:@@csv_cols).collect { |col| col.header }
    end

    def position_down_block
      Proc.new { |line, item|
        line<<item.detail
        line<<item.whouse_id
      }
    end

    def init_csv_cols
      csv_cols=[]
      csv_cols<< Csv::CsvCol.new(field: 'detail', header: 'Position')
      csv_cols<< Csv::CsvCol.new(field: 'whouse_id', header: 'Ware House',is_foreign: true,foreign: 'Whouse')
      csv_cols<< Csv::CsvCol.new(field: $UPMARKER, header: $UPMARKER)
      class_variable_set(:@@csv_cols,csv_cols)
    end

    def csv_cols
      class_variable_get(:@@csv_cols)
    end

    def init_uniq_key
      class_variable_set(:@@ukeys,%w(detail whouse_id))
    end

    def import_csv(csv)
      headers = [{field:'detail',header: 'Position'} ,
                 {field:'detail_new',header: 'Position New' ,null:true},
                 {field:'whouse_id',header:'Ware House',is_foreign: true,foreign: 'Whouse'},
                 {field: $UPMARKER,header: $UPMARKER,null:true}]

      msg=Message.new
      #begin
      line_no=0
      CSV.foreach(csv.file_path, headers: true, col_sep: csv.col_sep, encoding: csv.encoding) do |row|
        row.strip
        line_no+=1
        #if self.respond_to?(:csv_headers)
        #  raise(ArgumentError, "#{headers.join(' /')} 为必须包含列!") unless headers.empty?
        #end

        data={}
        headers.each do |col|
          raise(ArgumentError, "行:#{line_no} #{col[:field]} 值不可为空") if row[col[:header]].blank? && col[:null].nil?
          data[col[:field]]=row[col[:header]]
        end

        update_marker=(data.delete($UPMARKER).to_i==1)
        p = Position.find_by_detail(data['detail'])
        if update_marker
          if p
            #update
            if data['detail_new']
              data['detail'] = data['detail_new']
            end
            Position.trans_position
            data.delete('detail_new')
            p.update(data)
          else
            raise(ArgumentError, "行:#{line_no} Position 不存在对应的库位")
          end
        else
          #new
          if p
            next
          end
          data.delete('detail_new')
          Position.create(data)
        end
      end
      msg.result=true
      msg.content='数据导入成功'
      return msg
    end
  end
end