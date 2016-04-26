class NStorage < ActiveRecord::Base
  belongs_to :whouse, foreign_key: :ware_house_id
  belongs_to :position #, foreign_key: :position
  belongs_to :part, foreign_key: :partNr
  default_scope { where(locked: false) }

  before_validation :validate

  has_paper_trail

  def self.exists_package?(id)
    self.find_by_packageId(id)
  end

  def self.package_by_user user, id
    where(packageId: id, ware_house_id: user.location.whouse_ids)
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
                        ], types: [:string, :string, :string, :string, :string, :string, :string, :string]
        end
      }
    end
    p.to_stream.read
  end


  def self.to_xlsx n_storages
    p = Axlsx::Package.new
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
                        ], types: [:string, :string, :string, :string, :string, :string, :string, :string]
        end
      }
    end
    p.to_stream.read
  end
end
