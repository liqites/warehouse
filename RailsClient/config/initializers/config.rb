$SYNC_HOST = 'http://192.168.1.109:3000'
$OPEN_SYN_LOCK= false

config=YAML.load(File.open("#{Rails.root}/config/config.yaml"))
# load format
format_config=config['format']
$CSVSP=format_config[:csv_splitor] # csv splitor
$UPMARKER=format_config[:update_marker]
$FILE_MAX_SIZE=format_config[:file_max_size]
#load path
path_config=config['path']
$UPDATAPATH=path_config[:updata_file_path]
$DOWNLOADPATH=path_config[:download_file_path]
$TEMPLATEPATH=path_config[:template_file_path]
$DELIVERYPATH=path_config[:import_delivery_file_path]
