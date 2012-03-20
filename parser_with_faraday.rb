require 'faraday'
require 'faraday_middleware'

FILMS_LIMIT = 150
DOMAIN = "http://kinobaza.tv"
API_DOMAIN = "http://api.kinobaza.tv"
PATH_FOR_GENRES = "genres"
PATH_FOR_FILMS = "films/browse"

class KinobazaParser
  def self.parse!

    connection = Faraday.new(:url => API_DOMAIN) do |builder|
      builder.request  :url_encoded
      builder.adapter  :net_http
      builder.use FaradayMiddleware::ParseJson
    end

    resulted_array = []

    genres = connection.get(PATH_FOR_GENRES).env[:body]

    begin
      genres.each do |genre|
       
        resulted_array << parse_films(genre, connection)
      end
    rescue Exception => e
      p "sorry, but smth wrong: #{e}"
    end

    result = resulted_array.to_json

    File.open("result.json", "w") { |file| file << result }
  end

  def self.parse_films(genre, connection)
    record = { id: genre['id'], name: genre['name'] }
    films_response = connection.get do |req|
      req.url PATH_FOR_FILMS
      req.params['limit'] = FILMS_LIMIT
      req.params['genres'] = genre['id']
    end
    films = films_response.env[:body]
    record[:films] = films.collect { |f| { name: f['name'], url: "#{DOMAIN}/film/#{f['id']}" } }
    record
  end
end

KinobazaParser.parse!
