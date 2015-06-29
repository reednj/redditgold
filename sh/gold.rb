#!/usr/bin/ruby

require 'sequel'
require 'yaml'
require '../config/db.rb'
require '../lib/simpledb'

class App

	def initialize
		@db = SimpleDb.new
	end

	def main
		puts @db.db[:comments].first.to_yaml
	end
end

App.new.main