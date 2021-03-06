class RegexesController < ApplicationController
  before_action :set_regex, only: [:show, :edit, :update, :destroy]

  # GET /regexes
  # GET /regexes.json
  def index
    @package_label_regexes = Regex.where({type:RegexType::PACKAGE_LABEL}).order('code').all
    @orderitem_label_regexes = Regex.where({type:RegexType::ORDERITEM_LABEL}).order('code').all
  end

  # GET /regexes/1
  # GET /regexes/1.json
  def show
  end

  # GET /regexes/new
  def new
    @regex = Regex.new
  end

  # GET /regexes/1/edit
  def edit
  end

  # POST /regexes
  # POST /regexes.json
  def create
    @regex = Regex.new(regex_params)

    respond_to do |format|
      if @regex.save
        format.html { redirect_to @regex, notice: 'Regex was successfully created.' }
        format.json { render :show, status: :created, location: @regex }
      else
        format.html { render :new }
        format.json { render json: @regex.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /regexes/1
  # PATCH/PUT /regexes/1.json
  def update
    respond_to do |format|
      if @regex.update(regex_params)
        format.html { redirect_to @regex, notice: 'Regex was successfully updated.' }
        format.json { render :show, status: :ok, location: @regex }
      else
        format.html { render :edit }
        format.json { render json: @regex.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /regexes/1
  # DELETE /regexes/1.json
  def destroy
    @regex.destroy
    respond_to do |format|
      format.html { redirect_to regexes_url, notice: 'Regex was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def save
    @type=params[:type].to_i
    if @type==RegexType::PACKAGE_LABEL
      params[:regexes].each do |i, regex|
        if r=Regex.find_by_id(regex[:id])
          r.update(regex.except(:id))
        end
      end
      PackageLabelRegex.initialize_methods
    end
    render json: true
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_regex
    @regex = Regex.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def regex_params
    params.require(:regex).permit(:name, :code, :prefix_length, :prefix_string, :type, :suffix_length, :suffix_string, :regex_string, :localtion_id)
  end
end