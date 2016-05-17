# The config file should have the following format:
#
#---
# reednj:
#   consumer_key: N5FP6mMnW6cBGdtBsBTLgE81s
#   consumer_secret: LrCTb5Y8JcO5gTvBswACu48p3IqmFPgX2yOG3c45GBh4MtmR1X
#   access_token: 11646642-5jJ7aL5Iq34BA9ZkuiewkkN7GxrTK1v69CnlUcVy1T
#   access_token_secret: dJ3D13bxuN0LvTEVN2JJhvDSmRk8CsgFFB1jGy7MARMJV
#
module Twitter::Config
	class YAMLConfig
		def self.for_user(username, options = {})
			path = _twitter_config_file options[:path]
			config_data = YAML.load_file path
			user_config = config_data[username]
			raise "no config found for #{username} in file #{path}" if user_config.nil?

			return user_config
		end

		def self._twitter_config_file(path = nil)
			result = [path, "#{ENV['HOME']}/.twitter.yaml", './twitter.yaml'].compact.select{ |f| File.exist? f }.first
			raise 'could not find twitter config' if result.nil?
			return result
		end
	end
end

module Twitter::REST
	class Client
		def self.from_config(username, options = {})
			self.new Twitter::Config::YAMLConfig.for_user username, options

		end
	end
end
