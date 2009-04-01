#!/usr/bin/ruby

require 'rubygems'
require 'net/ssh'
require 'yaml'

require 'SysDep'
require 'Host'
require 'Service'
require 'Project'
require 'Colorify'

require 'EC2Wrap'

class Pac
  include Colorify

  # using ami ami-b31ff8da by default

  # maybe have a switch for quiet mode?
  # quiet mode would entail substituing all the stdout/stderr
  # lines for '.'
  #
  # maybe if left blank then launch a new ami??
  def install
    #verify

    hash = File.open('pac.yml') do |f| YAML.load f end

    if !ARGV[1].nil? then
      host = ARGV[1]
    else
      host =  hash["hosts"]["#{ARGV[1]}"][1]
    
      if host.nil? then
        not_valid("host")
      end
    end

    Net::SSH.start(host, 'root', :forward_agent => true) do |ssh|

      puts colorGreen("installing base components: ")
      apts = []
      hash["sysdeps"]["apts"].each do |a| apts << a[1] + " " end
      puts apts.to_s

      stdout = ""
      # DEBIAN_FRONTEND apparently is DEBCONF_FRONTEND sometimes..
      ssh.exec!("apt-get update; DEBIAN_FRONTEND='noninteractive' apt-get install -yq #{apts.to_s}") do |channel, stream, data|
        stdout << data if stream == :stdout or stream == :stderr
        puts stdout
      end

      puts colorGreen("pulling and building correct rubygems")
      stdout = ""
      ssh.exec!("wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz;" +
                " tar xzf rubygems-1.3.1.tgz; cd rubygems-1.3.1; ruby setup.rb; " +
                "ln -s /usr/bin/gem1.8 /usr/bin/gem") do |channel, stream, data|
        stdout << data if stream == :stdout or stream = :stderr
        print "."
      end

      puts colorGreen("installing gems:")
      gems = []
      hash["sysdeps"]["gems"].each do |a| gems << a[1] + " " end
      puts gems.to_s

      # should we prompt user to install merb or rails or should it go into
      # pac.yml?
      stdout = ""
      ssh.exec!("gem install #{gems.to_s} --no-ri --no-rdoc") do |channel, stream, data|
        stdout << data if stream == :stdout or stream = :stderr
        print "."
      end

      # debug
      puts stdout

      puts colorGreen "performing post-install xfs mounting..."
      stdout = ""
      ssh.exec!("mkfs.xfs -l version=1 /dev/sdh; echo \"/dev/sdh /vol xfs noatime 0 0\" >> /etc/fstab;" +
                " mkdir /vol; mount /vol;") do |channel, stream, data|
        stdout << data if stream == :stdout or stream = :stderr
        print "."
      end

    end

    puts colorGreen("done")
  end

  def provision
    ec2 = EC2Wrap.new
    ec2.provision
  end

  def upgrade
    hash = File.open('pac.yml') do |f| YAML.load f end
 
    if hash["projects"][ARGV[1]].nil? then
      not_valid('project')
      Process.exit
    else
      # use forwarding anytime we want to checkout repos
      Net::SSH.start(hash["hosts"].first[1], 'root', :forward_agent => true) do |ssh|

        #location of project
        dlocation = hash["projects"][ARGV[1]]["dlocation"]

        stdout = ""
        ssh.exec!("cd #{dlocation}; ls -1 #{ARGV[1]}") do |channel, stream, data|
          stdout << data if stream == :stdout
        end

        # get latest code
        if !stdout.empty? then

          #just need to upgrade and rebuild; sometimes I like to scp one file to
          #test it out -- reset ensures that I don't have conflicts
          stdout = ""
          ssh.exec!("cd #{dlocation}/#{ARGV[1]}; git reset --hard; git pull") do |channel, stream, data|
            stdout << data if stream == :stdout
          end

          puts stdout
          puts colorGreen('checking out latest copy')

        else
          puts colorGreen("Can't find #{ARGV[1]}: cloning a new copy")

          stdout = ""
          ssh.exec!("cd #{dlocation}; git clone " + hash["projects"][ARGV[1]]["repo"]) do |channel, stream, data|
            stdout << data if stream == :stdout
          end
          puts stdout
        end

        # check for custom build instructions
        if !hash["projects"]["#{ARGV[1]}"]["build"].nil? and
           !hash["projects"]["#{ARGV[1]}"]["build"].empty? then
        
          puts colorGreen("building #{ARGV[1]}")
          stdout = ""
          ssh.exec!(hash["projects"]["#{ARGV[1]}"]["build"]) do |channel, stream, data|
            stdout << data if stream == :stdout
          end

          puts stdout
        end
      end

    end
  end

  def verify
    puts "verifying dependencies"
    # loop through each system dependency and make
    # sure we have everything we need
  end

  def generate
    gen_menu
    option = STDIN.gets.chomp

    if option.eql? "1" then
      h = Host.new
      h.save
    elsif option.eql? "2" then
      p = Project.new
      p.load
    elsif option.eql? "3" then
      s = Service.new
      s.load
    elsif option.eql? "4" then
      s = SysDep.new
      s.generate
    elsif option.eql? "5" then
      Process.exit
    else
      not_valid('option')
    end
    generate
  end

  def not_valid(blah)
    puts colorRed("Not a Valid #{blah}.")
  end

  def gen_menu
    puts colorBlack("Generating")
    puts colorBlack("----------")
    puts "1) Add a Host"
    puts "2) Add a Project"
    puts "3) Add a Service"
    puts "4) Add System Dependencies"
    puts "5) Done"
    print colorBlue("> ")
  end

  def usage
    puts colorBlack("Usage: Pac {generate|install|upgrade|restart}")
    print colorBlue("\tgenerate:"); print colorBlack(" generate a deployment recipe\r\n")
    print colorBlue("\tprovision: "); print colorBlack(" provision a new EC2 instance\r\n")
    print colorBlue("\tіnstall: "); print colorBlack(" perform initial install [host]\r\n")
    print colorBlue("\tupgrade: "); print colorBlack(" upgrade deployment\r\n")
    print colorBlue("\trestart:"); print colorBlack(" restart [servicename]\r\n")
  end

  def restart
    hash = File.open('pac.yml') do |f| YAML.load f end

    if !ARGV[1].nil? then
      service =  hash["services"]["#{ARGV[1]}"]

      if service.nil? then
        not_valid('service')
        Process.exit
      else
        startcmd = service["start"]
        stopcmd = service["stop"]
      end
    else
      startcmd = hash["services"]["web"]["start"]
      stopcmd = hash["services"]["web"]["stop"]
    end

    # by default choose the first host and webserver
    Net::SSH.start(hash["hosts"].first[1], 'root') do |ssh|

      stdout = ""
      ssh.exec!("#{stopcmd}; #{startcmd}") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
    end
    
    puts colorGreen("restarting web service")
 
  end

end

p = Pac.new

if ARGV[0].eql? "generate" then
  p.generate
elsif ARGV[0].eql? "provision" then
  p.provision
elsif ARGV[0].eql? "install" then
  p.install
elsif ARGV[0].eql? "upgrade" then
  p.upgrade
elsif ARGV[0].eql? "restart" then
   p.restart
else
  p.usage
end
