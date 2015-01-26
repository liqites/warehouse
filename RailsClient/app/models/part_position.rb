class PartPosition < ActiveRecord::Base
  include Extensions::UUID
  include Import::PartPositionCsv
  belongs_to :position
  belongs_to :part

  belongs_to :sourceable, polymorphic: true

  FK=%w(position_id part_id)

  before_update :set_update_flag

  private
  def set_update_flag
    if self.part_id_changed? || self.position_id_changed?
      new_part_id=self.part_id
      new_position_id=self.position_id
      sourceable = self.sourceable
      PartPosition.create(part_id: new_part_id, position_id: new_position_id,sourceable: sourceable)
      self.part_id=self.part_id_was
      self.position_id =self.position_id_was
      self.is_delete=true
    end
  end
end
