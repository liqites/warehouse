class BaseState
  ORIGINAL = 0
  WAY = 1
  DESTINATION = 2
  RECEIVED = 3

  def self.display state
    case state
      when ORIGINAL
        '初始状态'
      when WAY
        '在途'
      when DESTINATION
        '到达'
      when RECEIVED
        '已接收'
      else
        '未知状态'
    end
  end

  def self.can_delete? state
    if state == ORIGINAL
      true
    else
      false
    end
  end

  def self.can_update? state
    if state == ORIGINAL
      true
    else
      false
    end
  end

  def self.can_change? old_state,new_state
    case old_state
      when ORIGINAL
        [WAY,DESTINATION].include? new_state
      when WAY
        [ORIGINAL,DESTINATION].include? new_state
      when DESTINATION
        [ORIGINAL,WAY,RECEIVED].include? new_state
      when RECEIVED
        [DESTINATION].include? new_state
      else
        false
    end
  end

  def self.state
    data = []
    self.constants.each do |c|
      v = self.const_get(c.to_s)
      data << [self.display(v),v]
    end
    data
  end
end