class Forklift < ActiveRecord::Base
  include Extensions::UUID
  include Extensions::STATE

  belongs_to :delivery
  belongs_to :whouse
  has_many :state_logs, as: :stateable
  #has_many :forklift_items, :dependent => :destroy
  has_many :packages #, :through => :forklift_items
  belongs_to :user
  belongs_to :stocker, class_name: "User"

  #add_to_delivery
  def add_to_delivery delivery_id
    self.delivery_id = delivery_id
    self.save
  end

  #remove_from_delivery
  def remove_from_delivery
    self.delivery_id = nil
    self.save
  end

  def generate_id
    "F#{Time.now.to_milli}"
  end
end
