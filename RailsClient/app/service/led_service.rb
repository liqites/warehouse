class LedService

  def self.update_led_state_by_position(position_id, led_state)
    return update_led_state(Led.find_by_position_id(position_id), led_state)
  end

  def self.update_led_state_by_id(id, led_state)
    return update_led_state(Led.find_by_id(id), led_state)
  end

  def self.update_led_state(led, led_state)
    msg=Message.new
    if led
      led.update(current_state: led_state)
      msg.result =true
      msg.content ='LED 状态已改变'
    else
      msg.content = 'LED 不存在'
    end
    puts '-----------------------msg------'
    puts msg.to_json
    return msg
  end

  #create 缺货单/需求单
  def self.create_stockout_list(led_id, normal_quantity=0, urgent_quantity=0) #is_emergency=false, box_quantity=1)
    if SysConfigCache.led_enable_value=='false'
      return
    end

    position = Led.find_by_id(led_id).position
    return if position.nil?

    part = position.default_part
    return if part.nil?

    source_id = PartPosition.find_by_part_id(part.id).sourceable_id
    builder = User.find(SysConfigCache.led_builder_value)
    args=[]

    if normal_quantity>0
      args <<{part_id: part.id, quantity: part.unit_pack * normal_quantity, box_quantity: normal_quantity,
              department: position.whouse.id, is_emergency: false}
    end

    if urgent_quantity>0
      args <<{part_id: part.id, quantity: part.unit_pack * urgent_quantity, box_quantity: urgent_quantity,
              department: position.whouse.id, is_emergency: true}
    end

    OrderService.create_with_items({order: {source_id: source_id}, order_items: args, nopart_items: args}, builder)
  end

end
