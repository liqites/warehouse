module CZ
#发运模块的统一接口
#所有函数只做最基本的发运逻辑和状态验证
  module Movable
    #include this module to your Model,make sure you have column below
    # :current_location_id,:destination_id,:state

    def dispatch(source, destination, sender_id)
      if state_switch_to(MovableState::WAY)
        self.sourceable = source
        self.destinationable = destination
        MovableRecord.update_or_create(self, {'id' => sender_id, 'type' => ImplUserType::SENDER, 'action' => __method__.to_s})
      end
    end

    def receive(receiver_id)
      if state_switch_to(MovableState::ARRIVED)
        self.current_positionable = self.destinationable
        MovableRecord.update_or_create(self, {'id' => receiver_id, 'type' => ImplUserType::RECEIVER, 'action' => __method__.to_s})
      end
    end

    def check(examiner_id)
      if state_switch_to(MovableState::CHECKED)
        MovableRecord.update_or_create(self, {'id' => examiner_id, 'type' => ImplUserType::EXAMINER, 'action' => __method__.to_s})
      end
    end

    def reject(rejector_id)
      if state_switch_to(MovableState::REJECTED)
        MovableRecord.update_or_create(self, {'id' => rejector_id, 'type' => ImplUserType::REJECTOR, 'action' => __method__.to_s})
      end
    end

    #for CZ::State
    def base_state
      MovableState.base(self.state)
    end

    def state_switch_to state
      if MovableState.before(state).include? self.get_state
        self.state = state
        true
      else
        false
      end
    end

    def get_state
      self.state
    end
  end
end