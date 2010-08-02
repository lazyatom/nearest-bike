require 'rubygems'
require 'johnson'
require 'hpricot'
require 'open-uri'
require 'ostruct'
require 'sinatra'
require 'haml'

def distance(a, b)
  #convert from degrees to radians
  a1 = a.lat.to_f * (Math::PI / 180)
  b1 = a.long.to_f * (Math::PI / 180)
  a2 = b.lat.to_f * (Math::PI / 180)
  b2 = b.long.to_f * (Math::PI / 180)

  r_e = 6378.135 #radius of the earth in kilometers (at the equator)
  #note that the earth is not a perfect sphere, r is also as small as
  r_p = 6356.75 #km at the poles

  #find the earth's radius at the average latitude between the two locations
  theta = (a.lat.to_f + b.lat.to_f) / 2

  r = Math.sqrt(((r_e**2 * Math.cos(theta))**2 + (r_p**2 * Math.cos(theta))**2) / ((r_e * Math.cos(theta))**2 + (r_p * Math.cos(theta))**2))

  #do the calculation with radians as units
  r * Math.acos(Math.cos(a1)*Math.cos(b1)*Math.cos(a2)*Math.cos(b2) + Math.cos(a1)*Math.sin(b1)*Math.cos(a2)*Math.sin(b2) + Math.sin(a1)*Math.sin(a2));
end

def stations
  page = open("https://web.barclayscyclehire.tfl.gov.uk/maps")
  doc = Hpricot(page.read)
  script = (doc/"script")[9].inner_html
  stations = script.scan(/station=\{(.*)\}/).flatten
  stations.map! do |line|
    Johnson.evaluate("({#{line}})")
  end
end

def nearest_station_with_bike_to(lat, long)
  here = OpenStruct.new
  here.lat = lat #51.519826
  here.long = long #-0.163281
  puts here
  near_stations_with_bikes = stations.select { |s| s.nbBikes.to_i > 0 }.sort_by { |s| distance(here, s) }

  near_stations_with_bikes.first
end
  
get "/" do
  haml :index
end

get "/near" do
  haml :near, :locals => {:station => nearest_station_with_bike_to(params[:lat], params[:long])}
end

__END__

@@ layout
%html
  %script{:type => "text/javascript", :src => "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"}
  = yield

@@ index
:javascript
  function locate(location) {
    jQuery.post("/near", {lat:location.coords.latitude,long:location.coords.longitude}, show);
  };
  function show(data) {
    document.write(data);
  };
  navigator.geolocation.getCurrentPosition(locate);

@@ near
%p Your nearest bike is at
%h1= station.name
%p
  = station.nbBikes
  Bikes,
  = station.nbEmptyDocks
  Empty docks