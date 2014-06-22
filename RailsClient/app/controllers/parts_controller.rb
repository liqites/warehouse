class PartsController < ApplicationController
  load_and_authorize_resource
  before_action :set_part, only: [:show, :edit, :update, :destroy]

  # GET /parts
  # GET /parts.json
  def index
    @parts = Part.all
    @parts = @parts.paginate(:page=>params[:page])
  end

  # GET /parts/1
  # GET /parts/1.json
  def show
  end

  # GET /parts/new
  def new
    @part = Part.new
  end

  # GET /parts/1/edit
  def edit
  end

  # POST /parts
  # POST /parts.json
  def create
    @part = Part.new(part_params)
    if !part_params.has_key?(:user_id)
      @part.user = current_user
    end

    respond_to do |format|
      if @part.save
        format.html { redirect_to @part, notice: 'Part was successfully created.' }
        format.json { render :show, status: :created, location: @part }
      else
        format.html { render :new }
        format.json { render json: @part.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /parts/1
  # PATCH/PUT /parts/1.json
  def update
    respond_to do |format|
      if @part.update(part_params)
        format.html { redirect_to @part, notice: 'Part was successfully updated.' }
        format.json { render :show, status: :ok, location: @part }
      else
        format.html { render :edit }
        format.json { render json: @part.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /parts/1
  # DELETE /parts/1.json
  def destroy
    @part.destroy
    respond_to do |format|
      format.html { redirect_to parts_url, notice: 'Part was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /parts/import_positions
  # GET /parts/import_positions.json
  def import_position

  end

  # POST /parts/do_import_positions
  # POST /parts/do_import_positions.json
  def do_import_positions
    msg=Message.new
    begin
      if params[:files].size==1
        file=params[:files][0]
        data=FileData.new(data: file, oriName: file.original_filename, path: $UPDATAPATH, pathName: "#{Time.now.strftime('%Y%m%d%H%M%S')}-#{file.original_filename}")
        data.saveFile
        csv=Csv::CsvConfig.new(encoding: Csv::CsvConfig.csv_write_encode(request.user_agent), col_sep: $CSVSP, file_path: data.full_path)
        msg=PartService.import_part_position csv
      else
        msg.content='未选择文件或只能上传一个文件'
      end
    rescue => e
      puts e.backtrace
      msg.content = e.message
    end
    render json: msg
  end

  # GET /parts/template_position
  # GET /parts/template_position.json
  def template_position
    file_name="part_position_csv_upload_template.csv"
    path=File.join($TEMPLATEPATH, file_name)
    send_file path, :type => 'application/csv', :filename => file_name
  end

  # GET /parts/download_positions
  # GET /parts/download_positions.json
  def download_positions
    file_name= 'part_positions_'+Time.now.strftime('%Y%m%d%H%M%S')+'.csv'
    path=File.join($DOWNLOADPATH, file_name)
    msg = Message.new
    msg.result = false
    begin
      File.open(path, 'wb') do |f|
        f.puts PartPosition.csv_headers.join($CSVSP)
        items=PartPosition.all
        items.each do |item|
          line=[]
          proc=PartPosition.down_block
          proc.call(line, item)
          f.puts line.join($CSVSP)
        end
      end
      msg.result=true
    rescue => e
      msg.content =e.message
    end
    if msg.result
      send_file path, :type => 'application/csv', :filename => file_name
    else
      render :index
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_part
    @part = Part.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def part_params
    #params[:part]
    params.require(:part).permit(:id, :unit_pack, :customernum, :user_id)
  end
end
