require 'yaml'

module YAML
	def self.load_first_file(files)
		files.each do |file|
			begin
				return load_file(file)
			rescue
			end
		end

		raise 'Was not able to open any of the listed files'
	end
end
