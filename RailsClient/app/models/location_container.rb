class LocationContainer < ActiveRecord::Base
  include Extensions::UUID
  include CZ::Movable
  include CZ::State

  has_ancestry
  belongs_to :container
  belongs_to :current_positionable, polymorphic: true
  belongs_to :sourceable, polymorphic: true
  belongs_to :destinationable, polymorphic: true
  belongs_to :location
  has_many :movable_records, :as => :movable

  has_ancestry
  # acts_as_tree


  # parent and child are Container
  # def self.add_child(parent, child, user_id, container_id)
  #   plc=self.find_latest_by_container_id(parent.id)
  # end


  def add(child)
    if child.root?
      child.descendants.each do |c|
        new_ancestor="#{self.child_ancestry}/#{c.ancestor_str}"
        c.update_attribute :ancestry, new_ancestor
      end
      child.update_attribute :parent, self
    end
  end

  def exists?(location_id)
    self.location_id.equal?(location_id)
  end

  def self.rebuild_exists?(container_id, user_id, location_id)
    old_lc=self.find_latest_by_container_id(container_id)
    unless old_lc.exists?(location_id)
      new_lc=LocationContainer.create(container_id: container_id, user_id: user_id, location_id: location_id)
      old_lc.rebuild_to_location(user_id, location_id, new_lc)
      return new_lc
    end
    return old_lc
  end


  def rebuild_to_location(user_id, location_id, parent)
    self.children.each do |lc|
      new_lc=self.find_latest_by_container_id(container_id)
      unless new_lc.exists?(location_id)
        new_lc=LocationContainer.create(container_id: container_id, user_id: user_id, location_id: location_id)
      end
      if new_lc.root?
        parent.add(new_lc)
        lc.rebuild_to_location(user_id, location_id, new_lc)
      end
    end
  end


  def self.find_latest_by_container_id(container_id)
    self.where(container_id: container_id).order(created_at: :desc).first
  end

  #
  def self.find_latest(container_id, location_id)
    self.where(container_id: container_id, location_id: location_id, state: INIT).order(created_at: :desc).first
  end

  # state can rebuild
  def can_rebuild?
    true
  end


  def self.destroy_by_container_id(container_id)
    self.where(container_id: container_id).update_all(is_delete: true, is_dirty: true, ancestry: nil)
  end

end