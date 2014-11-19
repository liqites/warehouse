class PackagePresenter<Presenter
  Delegators=[:id, :container_id, :user_id, :destinationable_id, :state, :part_id, :quantity, :fifo_time, :custom_quantity, :custom_fifo_time]
  def_delegators :@package, *Delegators

  def initialize(package)
    @package=package
    self.delegators = Delegators
  end


  def position_nr
    if position=PartService.get_position_by_whouse_id(self.part_id, self.destinationable_id)
      position.detail
    else
      ''
    end
  end

  def to_json
    {
        id: self.id,
        container_id: self.container_id,
        quantity_str: PackageLabelRegex.quantity_prefix_string+self.custom_quantity,
        part_id: PackageLabelRegex.part_prefix_string+self.part_id,
        quantity: self.quantity,
        check_in_time: PackageLabelRegex.date_prefix_string+self.custom_fifo_time,
        user_id: self.user_id,
        state: self.state,
        state_display: PackageState.display(self.state),
        position_nr: self.position_nr
    }
  end
end