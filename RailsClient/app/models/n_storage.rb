class NStorage < ActiveRecord::Base
  belongs_to :whouse, foreign_key: :ware_house_id
  belongs_to :position#, foreign_key: :position
  belongs_to :part, foreign_key: :partNr
  default_scope { where(locked: false) }

  before_validation :validate

  has_paper_trail

  def self.exists_package?(id)
    self.find_by_packageId(id)
  end

  def self.package_by_user user,id
    where(packageId: id,ware_house_id: user.location.whouse_ids)
  end

  def validate
    # TODO
    # 建议在API中实现

    # errors.add(:ware_house_id, "仓库不存在") unless Whouse.find_by_id(self.ware_house_id)
    # if self.ware_house && self.position.present?
    #   errors.add(:position, "源库位不存在") unless self.ware_house.positions.find_by_detail(self.position)
    # end
  end

  #
  # def whId
  #   whouse and whouse.id or nil
  # end

  def self.generate_diff_report(inventory_list_id)
    condition = {}
    condition['inventory_list_items.inventory_list_id']= inventory_list_id
    inventory_list=InventoryList.find_by_id(inventory_list_id)
    # NStorage.joins("LEFT JOIN inventory_list_items ON inventory_list_items.part_id = n_storages.partNr")
    #             .where(condition)
    #             .select("n_storages.partNr, sum(n_storages.qty) as qty, sum(inventory_list_items.qty) as qty2, sum(n_storages.qty)-sum(inventory_list_items.qty) as diff")
    #             .group('n_storages.partNr')
    results = []
    resultstemp = []
    @storages = NStorage.joins('inner join parts on parts.id=n_storages.partNr').
        where(ware_house_id: inventory_list.whouse_id)
                    .select("partNr,parts.nr as nr, sum(qty) as qty,count(*) as num")
                    .group('partNr')

    @inventory_list_items = InventoryListItem.joins(:part)
                                .where(condition)
                                .select("part_id,parts.nr as nr, sum(qty) as qty2,count(*) as num")
                                .group("part_id")

    @storages.each do |storage|
      # puts "#{storage.partNr}"
      # 零件号:0,库存数量:1,盘点数量:2,数量差异值:3,库存桶数:4,盘点桶数:5,桶数差异:6
      results.push([storage.nr, storage.qty, 0, storage.qty,storage.num,0,storage.num])
    end

    @inventory_list_items.each do |inventory_list_item|
      @flag = false
      results.each do |result|
        # @storages.each do |storage|
        if inventory_list_item.nr == result[0]
          #result.insert(2, inventory_list_item.qty2)
          result[2]=inventory_list_item.qty2
          result[3] = (result[1]||0) - result[2]
          #result[4]=
          result[5]=inventory_list_item.num
          result[6]= (result[4]||0) - result[5]
          @flag = true
          # break
        end
      end
      if !@flag
        results.push([Part.find_by_id(inventory_list_item.part_id).nr, 0, inventory_list_item.qty2, 0-inventory_list_item.qty2.to_f,0,inventory_list_item.num,0-inventory_list_item.num])
        #puts "part id is -- #{inventory_list_item.part_id}"
      end
    end
    return results
  end


  def self.to_total_xlsx n_storages, package_type_id
    p = Axlsx::Package.new
    wb = p.workbook
    wb.add_worksheet(:name => "sheet1") do |sheet|
      sheet.add_row ["序号", "零件号", "包装类型", "仓库号", "库位号", "数量", "FIFO", "创建时间", "唯一码"]
      n_storages.each_with_index { |n_storage, index|
        if n_storage.id && n_storage.id != ""
          package_type=PackageType.find_by_id(package_type_id)
          sheet.add_row [
                            index+1,
                            n_storage.part.present? ? n_storage.part.nr : '',
                            package_type.blank? ? (n_storage.part.present? ? n_storage.part.package_name : '') : package_type.name,
                            n_storage.whouse.present? ? n_storage.whouse.nr : '',
                            n_storage.position.present? ? n_storage.position.nr : '',
                            n_storage.total_qty,
                            n_storage.fifo.present? ? n_storage.fifo.localtime.strftime("%Y-%m-%d %H:%M") : '',
                            n_storage.created_at.present? ? n_storage.created_at.localtime.strftime("%Y-%m-%d %H:%M") : '',
                            n_storage.packageId
                        ], types: [:string, :string, :string, :string, :string, :string, :string,:string]
        end
      }
    end
    p.to_stream.read
  end


  def self.to_xlsx n_storages
    p = Axlsx::Package.new

    puts "9999999999999999999999999999999999"
    wb = p.workbook
    wb.add_worksheet(:name => "sheet1") do |sheet|
      sheet.add_row ["序号", "零件号", "包装类型", "唯一码", "仓库号", "库位号", "数量", "FIFO", "创建时间"]
      n_storages.each_with_index { |n_storage, index|
        if n_storage.id && n_storage.id != ""
          sheet.add_row [
                            index+1,
                            n_storage.part.present? ? n_storage.part.nr : '',
                            n_storage.part.present? ? n_storage.part.package_name : '',
                            n_storage.packageId,
                            n_storage.whouse.present? ? n_storage.whouse.nr : '',
                            n_storage.position.present? ? n_storage.position.nr : '',
                            n_storage.qty,
                            n_storage.fifo.present? ? n_storage.fifo.localtime.strftime("%Y-%m-%d %H:%M") : '',
                            n_storage.created_at.present? ? n_storage.created_at.localtime.strftime("%Y-%m-%d %H:%M") : ''
                        ], types: [:string, :string, :string, :string, :string, :string, :string,:string]
        end
      }
    end
    p.to_stream.read
  end
end
