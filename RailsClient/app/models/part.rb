class Part < ActiveRecord::Base
  include Extensions::UUID
  include Import::PartCsv

  belongs_to :user
  belongs_to :part_type
  has_many :part_positions, :dependent => :destroy
  has_many :positions, :through => :part_positions
  has_many :whouses, :through => :positions
  has_many :packages
  has_many :storages

  has_many :containers
  #has_many :inventory_list_items

  def self.exists?(id)
    Part.find_by_id(id)
  end

  def is_wire?
    self.part_type_id=='Wire'
  end

  def self.nr_by_regex(nr)
    nr.sub(/^P/,'')
  end

  def default_position wh
    position = self.positions.where(whouse_id: wh.id).first
    if position
      default_position = position.detail
    else
      wh.positions.first.blank? ? '' : wh.positions.first.detail
    end
  end
end