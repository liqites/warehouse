class BaseState
  ORIGINAL = 0
  WAY = 1
  DESTINATION = 2
  RECEIVED = 3
  REJECTED = 4

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
      when REJECTED
        '拒收'
      else
        '未知状态'
    end
  end

  def self.pre_states state
    case state
      when ORIGINAL
        [ORIGINAL]
      when WAY
        [ORIGINAL,WAY]
      when DESTINATION
        [DESTINATION,WAY]
      when RECEIVED
        [DESTINATION,REJECTED,RECEIVED]
      when REJECTED
        [DESTINATION,REJECTED,RECEIVED]
      else
        []
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
        [DESTINATION,ORIGINAL,WAY,RECEIVED].include? new_state
      when RECEIVED
        [DESTINATION].include? new_state
      else
        false
    end
  end

  def self.can_set_to? source,desc
    case source
      when ORIGINAL
        [WAY].include? desc
      when WAY
        [ORIGINAL,WAY].include? desc
      when DESTINATION
        [DESTINATION,RECEIVED].include? desc
      when RECEIVED
        [DESTINATION].include? desc
      else
        false
    end
  end

  def self.before_state? source,target
    case source
      when ORIGINAL
        false
      when WAY
        [ORIGINAL].include? target
      when DESTINATION
        [RECEIVED,DESTINATION,WAY].include? target
      when RECEIVED
        [WAY,DESTINATION].include? target
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
