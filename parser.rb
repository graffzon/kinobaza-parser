require 'net/http'
require 'json'
require 'benchmark'

FILMS_LIMIT = 150
DOMAIN = "http://kinobaza.tv"
API_DOMAIN = "http://api.kinobaza.tv"
PATH_FOR_GENRES = "genres"
PATH_FOR_FILMS = "films/browse"

class KinobazaParser
  def self.parse!
    threads = []
    resulted_array = []

    genres_json = Net::HTTP.get URI.parse("#{API_DOMAIN}/#{PATH_FOR_GENRES}")
    genres = JSON.parse genres_json

    begin
      genres.each do |genre|
        threads << Thread.new do
          resulted_array << parse_films(genre, threads)
        end

        # it seems that kinobaza's nginx think that it's a 
        # ddos or like that, so we need little sleep
        sleep 0.5
      end
    rescue Exception => e
      p "sorry, but smth wrong: #{e}"
    end

    threads.each {|thr| thr.join }

    result = resulted_array.to_json

    File.open("result.json", "w") { |file| file << result }
  end

  def self.parse_films(genre, threads)
    record = { id: genre['id'], name: genre['name'] }
    films_json = Net::HTTP.get URI.parse("#{API_DOMAIN}/#{PATH_FOR_FILMS}?limit=#{FILMS_LIMIT}&genres=#{genre['id']}")
    films = JSON.parse films_json
    record[:films] = films.collect { |f| { name: f['name'], url: "#{DOMAIN}/film/#{f['id']}" } }
    record
  end
end

KinobazaParser.parse!
