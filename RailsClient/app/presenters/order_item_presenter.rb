class OrderItemPresenter<Presenter
  Delegators=[:id,:order_id,:order,:location_id,:whouse_id,:user_id,:user,:part,:part_id,:part_type_id,:quantity,:is_emergency,:box_quantity,:is_finished,:out_of_stock,:handled]
  def_delegators :@order_item,*Delegators

  def initialize(order_item)
    @order_item = order_item
    self.delegators = Delegators
  end

  def location
    if self.location_id
      Location.find_by_id(self.location_id).name
    else
      ''
    end
  end

  def whouse
    # if self.whouse_id
    #   Whouse.find_by_id(self.whouse_id).name
    # else
    #   ''
    # end
  end

  # 要货地点
  def order_location
    self.user.location
  end

  # 发货地点
  def source
       OrderItemService.verify_location(self.user)
  end

  def creator
    if self.user_id
      User.find_by_id(self.user_id).name
    else
      ''
    end
  end

  def part_type
    if self.part_type_id
      PartType.find_by_id(self.part_type_id)
    else
      ''
    end
  end

  def position
    # if pp = OrderItemService.verify_department(self.whouse_id,self.part_id)
    #   pp.position.detail
    # else
    #   ''
    # end
  end



  def uniq_id
    self.location_id + self.part_id + self.is_emergency.to_s
  end

  def to_json(user)
    {
        id:self.id,
        order_id: self.order_id,
        location_id: self.location,
        whouse_id: self.order_location ? self.order_location.name : '',
        source_id: self.source ? self.source.id : '',
        source: self.source ? self.source.name : '',
        user_id: self.creator,
        part_id:  self.part.nr_for_user(user) ,
        part_type_id: self.part_type,
        is_emergency: self.is_emergency ? 1:0,
        quantity: self.quantity.to_s,
        position: self.position,
        uniq_id: self.uniq_id,
        box_quantity: self.box_quantity,
        is_finished: self.is_finished ? 1:0,
        out_of_stock: self.out_of_stock ? 1:0,
        handled: self.handled ? 1:0
    }
  end
end