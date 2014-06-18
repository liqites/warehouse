class LocationsController < ApplicationController
  load_and_authorize_resource
  before_action :set_location, only: [:show, :edit, :update, :destroy, :users, :whouses]

  # GET /locations
  # GET /locations.json
  def index
    @locations = Location.all
  end

  # GET /locations/1
  # GET /locations/1.json
  def show
  end

  # GET /locations/new
  def new
    @location = Location.new
  end

  # GET /locations/1/edit
  def edit
  end

  # POST /locations
  # POST /locations.json
  def create
    #@location = Location.new(params.require(:location).permit(:id,:name,:address,:tel))
    @location = Location.new(location_params)

    respond_to do |format|
      if @location.save
        format.html { redirect_to @location, notice: 'Location was successfully created.' }
        format.json { render :show, status: :created, location: @location }
      else
        format.html { render :new }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /locations/users
  def users
    @users = @locations.users
  end

  # GET /locations/whouses
  def whouses
    @whouses = @location.whouses
  end

  # PATCH/PUT /locations/1
  # PATCH/PUT /locations/1.json
  def update
    respond_to do |format|
      puts '##########################'
      puts location_params
      puts '##########################'
      if @location.update(location_params)
        format.html { redirect_to @location, notice: 'Location was successfully updated.' }
        format.json { render :show, status: :ok, location: @location }
      else
        format.html { render :edit }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.json
  def destroy
    if @location.is_base
      respond_to do |format|
        format.html { redirect_to locations_url, notice: 'Base Location can\'t be deleted.' }
        format.json { head :no_content }
      end
    else
      @location.destroy
      respond_to do |format|
        format.html { redirect_to locations_url, notice: 'Location was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_location
      @location = Location.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def location_params
      #params[:location]
      params.require(:location).permit(:name,:address,:tel)
    end
end
