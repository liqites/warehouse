class PartPosition < ActiveRecord::Base
  include Extensions::UUID
  belongs_to :position, :dependent => :destroy
  belongs_to :part, :dependent => :destroy

  FK=[:position_id, :part_id]

end
