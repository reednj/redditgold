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
	def cache(filename, maxage_sec)
		data = self.from_cache(filename, maxage_sec)
		
		if(data != nil)
			return data
		else
			data = yield

			File.open(self.get_path(filename), 'w') { |file| 
				# we need to wrap the data in an object, or the parsing can
				# fuck up for simple objects like strings, floats etc
				file.write({:data => data}.to_json) 
			}

			return data
		end

	end

	# checks the cache, and returns the file if it exits, and has not expired, otherwise
	# just returns nil
	def from_cache(filename, maxage_sec)
		path = self.get_path filename
		if File.exist?(path) && File.mtime(path) > Time.now - maxage_sec
			json_obj = JSON.parse(File.read(path), {:symbolize_names => true})
			return json_obj[:data]
		else
			return nil
		end
	end

	def get_path(filename)
		return File.join(@dir, filename)
	end


end