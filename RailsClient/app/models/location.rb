class Location < ActiveRecord::Base
  include Extensions::UUID
  include Import::LocationCsv

  has_many :users
  has_many :whouses, :dependent => :destroy
  belongs_to :destination, class_name: 'Location'

  def self.default_destination
    if d = Location.where(location_type:LocationType::DESTINATION).first
      d
    else
      Location.where(location_type:LocationType::BASE).first
    end
  end

  def self.list
    self.all.select { |l| l unless l.is_base }
  end

  def self.list_menu
    self.list.collect{|l| [l.name,l.id]}
  end
end
