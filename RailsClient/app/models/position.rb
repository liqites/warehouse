class Position < ActiveRecord::Base
  include Extensions::UUID
  include Import::PositionCsv

  belongs_to :whouse
  has_many :part_positions, :dependent => :destroy
  has_many :parts, :through => :part_positions

  validate :validate_save

  def validate_save
    errors.add(:id, '编号不可为空') if self.id.blank?
  end

  def generate_id
    "PS#{p.whouse_id}#{p.detail.gsub(/\s+/,'')}"
  end

  def self.trans_position
    t= Time.now
    h = t.strftime("%H").to_i
    if h >= 19 && h < 7
      t.strftime("%m %d 00")
    else
      t.strftime("%m %d 01")
    end
  end
end
