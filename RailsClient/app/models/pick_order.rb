class PickOrder < ActiveRecord::Base
  belongs_to :order
  belongs_to :pick_list
end
