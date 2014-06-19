class DeliveriesController < ApplicationController
  load_and_authorize_resource
  before_action :set_delivery, only: [:show, :edit, :update, :destroy]

  # GET /deliveries
  # GET /deliveries.json
  def index
    @deliveries = Delivery.all
  end

  # GET /deliveries/1
  # GET /deliveries/1.json
  def show
  end

  # GET /deliveries/new
  def new
    @delivery = Delivery.new
  end

  # GET /deliveries/1/edit
  def edit
  end

  # POST /deliveries
  # POST /deliveries.json
  def create
    @delivery = Delivery.new(delivery_params)

    respond_to do |format|
      if @delivery.save
        format.html { redirect_to @delivery, notice: 'Delivery was successfully created.' }
        format.json { render :show, status: :created, location: @delivery }
      else
        format.html { render :new }
        format.json { render json: @delivery.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deliveries/1
  # PATCH/PUT /deliveries/1.json
  def update
    if delivery_params.has_key?(:state)
      DeliveryService.set_state(@delivery, delivery_params[:state])
    end

    respond_to do |format|
      if @delivery.update(delivery_params)
        format.html { redirect_to @delivery, notice: 'Delivery was successfully updated.' }
        format.json { render :show, status: :ok, location: @delivery }
      else
        format.html { render :edit }
        format.json { render json: @delivery.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deliveries/1
  # DELETE /deliveries/1.json
  def destroy
    @delivery.destroy
    respond_to do |format|
      format.html { redirect_to deliveries_url, notice: 'Delivery was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def export
    json={}
    # delivery,forklift,package,package_position
    d=Delivery.find(params[:id])
    json[:delivery]=d
    json[:forklifts]=d.forklifts
    json[:packages]=[]
    json[:forklifts].each { |f|
      json[:packages] += f.packages }
    json[:package_positions]= []
    json[:packages].each { |p|
      json[:package_positions]<< p.package_position }
    json[:state_logs]=d.state_logs
    json[:forklifts].each { |f|
      json[:state_logs]+=f.state_logs }
    json[:packages].each { |p|
      json[:state_logs]+=p.state_logs }
    send_data json.to_json, :filename => "#{d.id}.json"
  end

  def import

  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_delivery
    @delivery = Delivery.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def delivery_params
    #params[:delivery]
    params.require(:delivery).permit(:state, :remark)
  end
end
