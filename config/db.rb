require_relative './yaml-load_first_file'

AppConfig = YAML.load_first_file([
	"#{ENV['HOME']}/config/gold.db.conf",
	"/home/reednj/code/config_backup/gold.db.conf",
	"./config/dev.config.yaml"
])
