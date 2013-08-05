
class FileCache
	def initialize(dir='cache')
		@dir=dir

		if !File.directory?(@dir)
			Dir.mkdir(@dir)
		end
	end

	def cache(filename, maxage_sec)
		data = self.fromCache(filename, maxage_sec)
		
		if(data != nil)
			return data
		else
			data = yield
			File.write(self.getPath(filename), data.to_json)
			return data
		end

	end

	# checks the cache, and returns the file if it exits, and has not expired, otherwise
	# just returns nil
	def fromCache(filename, maxage_sec)
		path = self.getPath filename
		if File.exist?(path) && File.mtime(path) > Time.now - maxage_sec
			return JSON.parse(File.read(path), {:symbolize_names => true})
		else
			return nil
		end
	end

	def getPath(filename)
		return File.join(@dir, filename)
	end


end