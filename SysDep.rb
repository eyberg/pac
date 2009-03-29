require 'Colorify'

class SysDep

  def generate
    gen_menu
    option = STDIN.gets.chomp

    puts "option:#{option}:"
    if option.eql? "1" then
      newgem
    elsif option.eql? "2" then
      newapt
    elsif option.eql? "3" then
      newtarball
    else
      not_valid
    end
  end

  def not_valid
    puts "Not a Valid Option."
  end

  def gen_menu
    puts colorBlack("Create New Dependency")
    puts colorBlack("----------")
    puts colorBlack("1) Add Ruby Gem")
    puts colorBlack("2) Add Apt Package")
    puts colorBlack("3) Add tarball (url)")
    print colorBlue("> ")
  end

  def newapt
    puts colorBlack("creating a new (deb/apt) pkg depedency")
    puts colorBlack("-------------------")
    print colorBlack("Name: ")
    name = STDIN.gets.chomp
    print colorBlack("Pkg-Name: ")
    source = STDIN.gets.chomp

    hash = File.open('pac.yml') do |f| YAML.load f end

    if hash.nil? or hash.eql? false then
      hash = {}
    end

    if hash["sysdeps"].nil? then
      sysdeps = {}
      hash["sysdeps"] = sysdeps
      sysdeps["apts"] = {}
    end

    if hash["sysdeps"]["apts"].nil? then
      hash["sysdeps"]["apts"] = {}
    end

    hash["sysdeps"]["apts"]["#{name}"] = source 

    File.open("pac.yml", 'w') do |f|
      f.puts hash.to_yaml
    end
  end

  def newtarball
    puts colorBlack("creating a new tarball depedency")
    puts colorBlack("-------------------")
    print colorBlack("Name: ")
    name = STDIN.gets.chomp
    print colorBlack("Source: ")
    source = STDIN.gets.chomp

    hash = File.open('pac.yml') do |f| YAML.load f end

    if hash.nil? or hash.eql? false then
      hash = {}
    end

    if hash["sysdeps"].nil? then
      sysdeps = {}
      hash["sysdeps"] = sysdeps
      sysdeps["tarballs"] = {}
    end

    if hash["sysdeps"]["tarballs"].nil? then
      hash["sysdeps"]["tarballs"] = {}
    end

    hash["sysdeps"]["tarballs"]["#{name}"] = source 

    File.open("pac.yml", 'w') do |f|
      f.puts hash.to_yaml
    end
  end

  def newgem
    puts colorBlack("creating a new ruby gems depedency")
    puts colorBlack("-------------------")
    print colorBlack("Name: ")
    name = STDIN.gets.chomp
    print colorBlack("Source (press ENTER to default to rubygems) : ")
    source = STDIN.gets.chomp

    hash = File.open('pac.yml') do |f| YAML.load f end

    if hash.nil? or hash.eql? false then
      hash = {}
    end

    if hash["sysdeps"].nil? then
      sysdeps = {}
      hash["sysdeps"] = sysdeps
      sysdeps["gems"] = {}
    end

    if hash["sysdeps"]["gems"].nil? then
      hash["sysdeps"]["gems"] = {}
    end

    hash["sysdeps"]["gems"]["#{name}"] = source 

    File.open("pac.yml", 'w') do |f|
      f.puts hash.to_yaml
    end
  end
end
