class LocationPresenter<Presenter
  Delegators=[:id, :nr, :tenant_id, :name, :created_at, :updated_at,:receive_mode]
  def_delegators :@location, *Delegators

  def initialize(location)
    @location = location
    self.delegators = Delegators
  end

  def to_json_with_destination
    json=self.to_json
    if @location.default_destination
      json[:destination]=LocationPresenter.new(@location.default_destination).to_json
    end
    json
  end
end