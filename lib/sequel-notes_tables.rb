require 'sequel'

module NotesTableHelpers
	def self.included(base)
 		base.extend ClassMethods
	end
	
	def notes
		association_name = :raw_notes

		unless respond_to? association_name.to_sym
			raise "cannot add 'notes' method - association #{association_name} doesn't exist" 
		end

		# i know there are better ways to map hashes in newer versions of ruby
		# but just do it the simple way here
		notes_hash = {}
		send(association_name.to_sym).each do |n|
			notes_hash[n.field_name.to_sym] = n.field_value
		end

		notes_hash
	end

	def has_note?(field_name)
		!notes[field_name.to_sym].nil?
	end

	def add_note(field_name, field_value)
		if self.class._notes_class_name.nil?
			raise 'notes_class method required to add_notes' 
		end

		# todo: this will fail if the assoc. name is non-standard...
		add_raw_note(self.class._notes_class.new { |n|
			n.field_name = field_name.to_s
			n.field_value = field_value
		})
	end

	# this will create, update or delete the note
	#
	# setting the value to nil will delete it
	#
	def set_note(field_name, field_value)
		note = raw_notes.select{ |n| n.field_name == field_name.to_s }.first

		if note.nil?
			add_note field_name, field_value
		elsif field_value.nil?
			note.destroy
		else
			note.field_value = field_value
			note.save_changes
		end
	end

	def set_notes(hash)
		db.transaction do
			hash.each do |k, v|
				set_note k, v
			end
		end
	end

	def add_notes(hash)
		db.transaction do
			hash.each do |k, v|
				add_note k, v
			end
		end
	end
	
	module ClassMethods
		def add_notes_field(field_name, options = {})
			define_method field_name.to_sym do
				notes[field_name.to_sym ]
			end

			if options[:read_only] != true
				define_method "#{field_name}=".to_sym do |v|
					set_note field_name, v
				end
			end
		end

		def add_notes_assoc(class_name)
			@notes_class_name = class_name.to_s
			one_to_many :raw_notes, :class => _notes_class_name, :key => primary_key
		end

		def _notes_class_name
			@notes_class_name
		end

		def _notes_class
			Object.const_get _notes_class_name
		end
	end
end


