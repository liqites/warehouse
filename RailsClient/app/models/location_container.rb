class LocationContainer < ActiveRecord::Base
  include Extensions::UUID
  include CZ::Movable
  include CZ::State
  # has_ancestry
  acts_as_tree
  belongs_to :container
  belongs_to :current_positionable, polymorphic: true
  belongs_to :sourceable, polymorphic: true
  belongs_to :destinationable, polymorphic: true

  belongs_to :location

  has_many :movable_records, :as => :movable

  def add(lc)
    if lc.root?

    end
  end
end