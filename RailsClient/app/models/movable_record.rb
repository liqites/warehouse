class MovableRecord < ActiveRecord::Base
  include Extensions::UUID

  belongs_to :movable, polymorphic: true

  def self.update_or_create(movable,impl)
    puts movable
    puts impl
    unless mr = self.where({movable:movable,impl_action: impl["action"]}).first
      self.create({movable:movable,impl_id:impl['id'],impl_user_type:impl['type'],impl_user:ImplUserType.display(impl['type']),impl_action:impl['action'],impl_time:Time.now})
    else
      mr.update({impl_id:impl['id'],impl_user_type:impl['type'],impl_user:ImplUserType.display(impl['type']),impl_time:Time.now})
    end
  end
end
