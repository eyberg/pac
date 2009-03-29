require 'Colorify'

# projects can be any sort of software project
# that is deployed often: in our case it consists
# of bluffparse and our merb web service
class Project
  include Colorify

  def load
    project = {}

    puts colorBlack("creating a new project")
    puts colorBlack("-------------------")
    print colorBlack("Name: ")
    project["name"] = STDIN.gets.chomp
    
    print colorBlack("Repo: ")
    project["repo"] = STDIN.gets.chomp

    print colorBlack("Deploy Location: ")
    project["dlocation"] = STDIN.gets.chomp

    print colorBlack("Custom Build Command: ")
    project["build"] = STDIN.gets.chomp


    hash = File.open('pac.yml') do |f| YAML.load f end

    if hash.nil? or hash.eql? false then
      hash = {}
    end

    if hash["services"].nil? then
      projects = {}
      hash["projects"] = projects
    end

    hash["projects"]["#{project["name"]}"] = project
    File.open("pac.yml", 'w') do |f|
      f.puts hash.to_yaml
    end
  end
end
