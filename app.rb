
require 'sinatra'
require "sinatra/reloader" if development?
require 'sequel'
require 'json'

require './config/db'
require './lib/simpledb'


get '/' do
	sdb = SimpleDb.new

	goldCost = 3.99
	dayCount = sdb.goldCount(1) * goldCost
	weekCount = sdb.goldCount(7) * goldCost
	monthCount = sdb.goldCount(30) * goldCost

	erb :index, :locals => {
		:dayCount => dayCount,
		:weekCount => weekCount,
		:monthCount => monthCount,
		:dayRate => dayCount / (1 * 24),
		:weekRate => weekCount / (7 * 24),
		:monthRate => monthCount / (30 * 24),
		:dailyData => sdb.revenueByDay(30),
		:topComments => sdb.topComments(7)
	}
end

