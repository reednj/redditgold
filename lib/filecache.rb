# FileCache
#
# Caches an object on the file system in json format.
#
# By default stores the data in ./cache. Pass a different path to the constructor to
# change this
#
class FileCache
	def initialize(dir='cache')
		@dir=dir

		if !File.directory?(@dir)
			Dir.mkdir(@dir)
		end
	end

	# Cache the object produced by the passed block in +filename+
	# If the file already exists, and the mtime is less than the max
	# age, then the file will be parsed and returned
	def cache(filename, max_age)
		data = self.from_cache(filename, max_age)
		
		if(data != nil)
			return data
		else
			data = yield
			self.to_cache filename, data
			return data
		end

	end

	def to_cache(filename, data, options=nil)
		options ||= {}
		tmp_file = "#{filename}.tmp"
		File.open(self.get_path(tmp_file), 'w:UTF-8') { |file|
			# we need to wrap the data in an object, or the parsing can
			# fuck up for simple objects like strings, floats etc
			data = {:data => data}.to_json if !options[:plain_text] == true
			file.write(data)
		}

		File.rename(self.get_path(tmp_file), self.get_path(filename))
	end

	def valid_cache(filename, max_age)
		File.exist?(self.get_path(filename)) && self.age(filename) <= max_age
	end

	# checks the cache, and returns the file if it exits, and has not expired, otherwise
	# just returns nil
	def from_cache(filename, max_age, options=nil)
		options ||= {}
		path = self.get_path filename

		return nil if !self.valid_cache(filename, max_age)

		begin
			data = self.read(path)
			return data if options[:plain_text] == true
			json_obj = JSON.parse(data, {:symbolize_names => true})
			return json_obj[:data]
		rescue StandardError => e
			$stderr.puts "Warning: Could not read cache for #{filename} (#{e})"
			return nil
		end
	
	end

	def mtime(filename)
		path = self.get_path(filename)
		File.mtime(path)
	end

	def age(filename)
		Time.now - self.mtime(filename)
	end

	def read(path)
		data = nil
		File.open(path, 'r:UTF-8') { |file| 
			data = file.read 
		}
		return data
	end


	def get_path(filename)
		return File.join(@dir, filename)
	end
end