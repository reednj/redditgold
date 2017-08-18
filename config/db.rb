require './config/yaml-load_first_file'

AppConfig = YAML.load_first_file([
	"#{ENV['HOME']}/config/gold.db.conf",
	"#{ENV['HOME']}/code/config_backup/gold.db.conf",
	"./config/dev.config.yaml"
])
