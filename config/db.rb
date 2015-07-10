require 'ostruct'

AppConfig = OpenStruct.new({
	:db => OpenStruct.new({
		:username => 'linkuser',
		:password => '',
		:host => '127.0.0.1',
		:database => 'gold'
	})
})
