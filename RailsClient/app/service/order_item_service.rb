class OrderItemService
	#=============
	#create
	#params @position, @part_id, @quantity
	#=============
	def self.create args,current_user
		unless pos = verify_position(args[:position])
			return nil
		end

		unless verify_part_id args[:part_id],current_user
			return nil
		end

		part = Part.find_by_id(part_id)

		unless verify_quantity args[:quantity]
			return nil
		end

		quantity = filt_quantity(args[:quantity])

		params = {}
		#here location and whouse is
		params[:location_id] = position.whouse.location_id
		params[:whouse_id] = position.whouse_id
		params[:source_id] = position.sourceable_id
		params[:user_id] = current_user.id
		params[:part_id] = part.id
		params[:part_type_id] = part.part_type_id
		params[:quantity] = quantity

		item = OrderItem.new(params)
		if item.save
			return item
		end
	end

	#=============
	#verify position exits?
	#and part exits in this position?
	#=============
	def self.verify_position pos,part_id
		unless position = Position.find_by_detail(pos)
			return nil
		end

		#dose this part in this position?
		unless position.parts.ids.include?(part_id)
			return nil
		end

		return position
	end

	#=============
	#verify part id
	#=============
	def self.verify_part_id part_id,current_user
		PartService.validate_id part_id,current_user
		Part.find_by_id part_id
	end

	#=============
	#verify quantity,
	#need to know 
	#=============
	def self.verify_quantity quantity
		
	end
end