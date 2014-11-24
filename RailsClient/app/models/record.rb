class Record < ActiveRecord::Base
  include Extensions::UUID

  belongs_to :recordable, polymorphic: true
  belongs_to :destinationable, polymorphic: true

  def self.update_or_create(recordable,impl,destinationable=nil)
    unless mr = self.where({recordable:recordable,impl_action: impl["action"]}).first
      self.create({destinationable:destinationable,recordable:recordable,impl_id:impl['id'],impl_user_type:impl['type'],impl_action:impl['action'],impl_time:Time.now})
    else
      mr.update({impl_id:impl['id'],impl_user_type:impl['type'],impl_time:Time.now})
    end
  end
end
