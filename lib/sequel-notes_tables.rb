require 'sequel'

# NotesTableHelpers
#
# these helpers are used on Sequel::Model classes to make it easier to
# manage 'notes' tables. Notes tables are a useful pattern to extend the 
# schema of a table, if only a small fraction of the rows require a certain
# field.
#
# For example, given a table like this:
#
# 	comments
# 	 - comment_id int
# 	 - user_id:int
# 	 - context:string
# 	 - created_date:time
#
# we could create a notes table with the following schema:
#
# 	comment_notes
# 	 - comment_id:int
# 	 - field_name:string
# 	 - field_value:string
#
# Managing these notes through a standard association is not that pleasant. This
# module makes it easy to read and write to these notes fields
#
# Here is an example using the previous schema:
#
# 	class CommentNote < Sequel::Model
# 	end
#
# 	class Comment < Sequel::Model
#		include NotesTableHelpers
#		add_notes_assoc 'CommentNote'
#		add_notes_field :spam_rating
#		add_notes_field :hide_comment
# 	end
#
# dedicated methods can be added using the :add_notes_field: method. All the notes
# can also be accessed as a hash through :notes:
#
module Sequel::Model::NotesTableHelpers
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

		def create_notes_table?(options = {})
			column_name = (options[:key] || primary_key || 'id').to_sym
			column_type = 'int'
			notes_table_name = options[:table_name].to_sym

			schema = db.schema table_name
			pk = schema.select {|c| !!c[1][:primary_key] }.first[1]
			column_type = pk[:db_type]

			db.create_table? notes_table_name.to_sym do
				column column_name, column_type
				String :field_name, :size => 32
				String :field_value, :size => 64
				primary_key [column_name, :field_name]
			end
		end
	end
end


