require 'Colorify'

class Host
  include Colorify

  def save
    puts colorBlack("creating a new host")
    puts colorBlack("-------------------")
    print colorBlack("Host: ")
    host = STDIN.gets.chomp

    hash = File.open('pac.yml') do |f| YAML.load f end

    if hash.nil? or hash.eql? false then
      hash = {}
    end

    if hash["hosts"].nil? then
      hosts = {}
      hash["hosts"] = hosts
    end

    ncount = hash["hosts"].count

    hash["hosts"]["host#{ncount+1}"] = host

    File.open("pac.yml", 'w') do |f|
      f.puts hash.to_yaml
    end
  end
end
