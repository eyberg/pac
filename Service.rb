require 'Colorify'

# services are stuff like merb or mysql or memcached
# that might not necesarily be deployed every time
# we want to restart
class Service
  include Colorify

  def load
    service = {}

    puts colorBlack("creating a new service")
    puts colorBlack("-------------------")
    print colorBlack("Name: ")
    service["name"] = STDIN.gets.chomp
    
    print colorBlack("Start Cmd: ")
    service["start"] = STDIN.gets.chomp

    print colorBlack("Stop Cmd: ")
    service["stop"] = STDIN.gets.chomp

    hash = File.open('pac.yml') do |f| YAML.load f end

    if hash.nil? or hash.eql? false then
      hash = {}
    end

    if hash["services"].nil? then
      services = {}
      hash["services"] = services
    end

    hash["services"]["#{service["name"]}"] = service

    File.open("pac.yml", 'w') do |f|
      f.puts hash.to_yaml
    end
  end
end
