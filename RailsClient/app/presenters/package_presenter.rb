class PackagePresenter<Presenter
  Delegators=[:id, :container_id, :user_id, :state, :container]
  def_delegators :@logistics_container, *Delegators

  def initialize(logistics_container)
    @logistics_container=logistics_container
    @package=logistics_container.package
    self.delegators = Delegators
  end

  def position
    if @logistics_container.destinationable && @logistics_container.destinationable_type == Whouse.to_s
      if position=PartService.get_position_by_whouse_id(@package.part_id, @logistics_container.destinationable_id)
        return position
      end
    end
    nil
  end
  #需要明确，logistics_container的package的destination应该是warehouse而不是position
  def position_nr
    # if self.position
    #   return self.position.display
    # elsif @logistics_container.destinationable
    #   return @logistics_container.destinationable.name
    # end
    # ''

    @package.storage_position_display || ''
  end

  def part_id_display(user=nil)
    if user
    @package.part.blank? ? '' : @package.part.nr_for_user(user)
    else

      end
  end

  def quantity_display
    @package.quantity.to_s#_display || ''
  end

  def fifo_time_display
    @package.storage_fifo_display || ''
  end

  def created_at
    @logistics_container.created_at.blank? ? '' : @logistics_container.created_at.strftime('%Y-%m-%d %H:%M')
  end

  def destinationable_name
    @logistics_container.destinationable.nil? ? "":@logistics_container.destinationable.name
  end

  def sum_packages
    1
  end

  def possible_departments
    pos = []

    puts "------------------#{self.container.id}"
    self.container.part.whouses.each do |ps|
      pos << {id:ps.id,name:ps.name}
    end
    pos
  end

  def self.init_json_presenters params,user
    params.map { |param| self.new(param).to_json(user) }
  end

  def to_json(user)
    {
        id: self.id,
        container_id: self.container_id,
        quantity_display: self.quantity_display,
        part_id_display: self.part_id_display(user),
        quantity: @package.quantity,
        fifo_time_display: self.fifo_time_display,
        user_id: self.user_id,
        state: self.state,
        state_display: @logistics_container.state_display,
        position_nr: self.position_nr,
        possible_department: self.possible_departments
    }
  end

  # def to_json_simple
  #   {
  #       id: self.id,
  #       container_id:self.container_id,
  #       quantity_str: PackageLabelRegex.quantity_prefix_string+@package.custom_quantity,
  #       part_id: PackageLabelRegex.part_prefix_string+@package.part_id,
  #       quantity: @package.quantity,
  #       check_in_time: PackageLabelRegex.date_prefix_string+@package.custom_fifo_time,
  #       user_id: self.user_id,
  #       state: self.state,
  #       state_display: '',
  #       position_nr: ''
  #   }
  # end
end