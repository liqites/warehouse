class OrderItemService
  #=============
  #create
  #params @position, @part_id, @quantity
  #=============
  def self.new location, part, quantity, is_emergency, box_quantity, current_user
    params = {}
    #here location and whouse is
    params[:location_id] = location.id#part_position.position.whouse.location_id
    #params[:whouse_id] = part_position.position.whouse_id
    params[:user_id] = current_user.id
    params[:part_id] = part.id
    params[:part_type_id] = part.part_type_id
    params[:quantity] = quantity
    params[:is_emergency] = is_emergency
    params[:box_quantity] = box_quantity

    item = OrderItem.new(params)
=begin
		if item.save
			return item
		end
=end
    return item
  end

  def self.verify args, current_user
    if verify_part_id(args[:part_id], current_user) && verify_position(args[:position], args[:part_id]) && verify_quantity(args[:quantity])
      return true
    else
      return false
    end
  end

  #=============
  #verify department exits?
  #and part exits in this position?
  #=============
  def self.verify_department pos
     Whouse.find_by_nr(pos)
  end

  def self.verify_location user
    user.location.order_source_location
  end

  #=============
  #verify part id
  #=============
  def self.verify_part_id part_nr, current_user
    if PartService.validate_id part_nr, current_user
      Part.find_by_nr part_nr
    end
  end

  def self.verify_user_part part_nr,current_user
    PartService.validate_user_part(part_nr,current_user)
  end

  #=============
  #verify quantity,
  #need to know
  #=============
  def self.verify_quantity quantity
    return quantity
  end

  #=============
  #exists? id
  #=============
  def self.exists? id
    OrderItem.find_by_id id
  end

  #=============
  #update
  #=============
  def self.update args
    true
  end
end
