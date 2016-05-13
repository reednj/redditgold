
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
