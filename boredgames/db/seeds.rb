# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
page = 0

results = []
5.times do 
	page += 1
	doc = Nokogiri::XML(open("http://boardgamegeek.com/browse/boardgame/page/#{page}"))
	parsed_data = doc.css("a").map { |link| link['href'] }.select{ |path| path =~ /\A\/boardgame/ }.map { |url| url.split("/") }.map { |element| element[2] }.uniq
 	parsed_data.delete_if { |id| id == "random"}
 	results << parsed_data
end

results.flatten!.uniq!

def parser(id)
	uri = URI("http://www.boardgamegeek.com/xmlapi2/thing?type=boardgame&id=#{id}")
	Nokogiri::XML(Net::HTTP.get(uri))
end

results.each do |stuff|
	game_data = parser(stuff)
	title = game_data.css('name')[0][:value]
	description = game_data.css("description").text.gsub(/&#10;/, "")
	play_time = game_data.css('playingtime')[0][:value]
	min_players = game_data.css('minplayers')[0][:value]
	max_players = game_data.css('maxplayers')[0][:value]
	published = game_data.css('yearpublished')[0][:value]
	mechanics = game_data.css("link").select { |link| link[:type] == "boardgamemechanic" }.map { |link| link[:value] }
	
	game = Game.create({name: title,
											description: description,
											play_time: play_time,
											min_players: min_players,
											max_players: max_players,
											year_published: published})

	mechanics.each do |mechanic|
		game.mechanics.find_or_create_by(description: mechanic)
	end
	
	sleep 1
end