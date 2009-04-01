require 'EC2'
require 'Colorify'

class EC2Wrap
  include Colorify

  def provision
    hash = File.open('ec2.yml') do |f| YAML.load f end

    ec2 = EC2::Base.new(:access_key_id => hash["access_key"], :secret_access_key => hash["secret_key"])

    # create ubuntu jaunty jakolope instance
    ni = ec2.run_instances(:image_id => "ami-b31ff8da", :availability_zone => "us-east-1a", :key_name => hash["key_name"])
    rid =  ni["reservationId"]
    instance = ec2.describe_instances(:reservationID => rid)
    count = instance.reservationSet.item.count

    # create volume
    vol = ec2.create_volume( :availability_zone => "us-east-1a", :size => "5" )

    instance = ec2.describe_instances(:reservationID => rid)
    instanceid = instance.reservationSet.item[count-1].instancesSet.item[0].instanceId

    #attach
    flag = true
    while(flag) do 
      begin
        puts colorBlack ".."
        ec2.attach_volume( :volume_id => vol.volumeId, :instance_id => instanceid, :device => '/dev/sdh')
        flag = false
      rescue
        sleep 1
      end
    end

    # need to re-associate our instance to figure out what the dns is
    instance = ec2.describe_instances(:reservationID => rid)
    dnsname = instance.reservationSet.item[count-1].instancesSet.item[0].dnsName
    puts colorBlue dnsname
  end

end
