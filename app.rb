
require 'sinatra'
require "sinatra/reloader" if development?
require 'sequel'
require 'json'

require './config/db'
require './lib/simpledb'
require './lib/filecache'


get '/' do
	sdb = SimpleDb.new
	fc = FileCache.new
	goldCost = 3.99

	locals = fc.cache('gold.data', 300) do
		data = {
			:dayCount => sdb.goldCount(1) * goldCost,
			:weekCount => sdb.goldCount(7) * goldCost,
			:monthCount => sdb.goldCount(30) * goldCost,
			:dailyData => sdb.revenueByDay(30),
			:topComments => sdb.topComments(7)[0..5]
		}

		data = data.merge({ 
			:dayRate => data[:dayCount] / (1 * 24),
			:weekRate => data[:weekCount] / (1 * 24),
			:monthRate => data[:monthCount] / (1 * 24)
		})

		puts 'Cache Refresh'
		data
	end

	gitdir = '/home/reednj/code/redditgold.git/.git' if !settings.development?
	locals[:version] = GitVersion.current(gitdir)

	erb :index, :locals => locals
end

class GitVersion
	def self.current(gitdir='./.git')
		return FileCache.new.cache('git.version', 3600 * 24 * 7) { `git --git-dir=#{gitdir} describe --long` }
	end
end