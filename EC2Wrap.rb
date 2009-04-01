require 'EC2'
require 'Colorify'

class EC2Wrap
  include Colorify

  def provision
    hash = File.open('ec2.yml') do |f| YAML.load f end

    ec2 = EC2::Base.new(:access_key_id => hash["access_key"], :secret_access_key => hash["secret_key"])

    # create ubuntu jaunty jakolope instance
    ni = ec2.run_instances(:image_id => "ami-b31ff8da")
    rid =  ni["reservationId"]
    instance = ec2.describe_instances(:reservationID => rid)

    # create volume
    vol = ec2.create_volume( :availability_zone => "us-east-1c", :size => "5" )

    dnsname = instance.reservationSet.item[0].instancesSet.item[0].dnsName
    instanceid = instance.reservationSet.item[0].instancesSet.item[0].instanceId

    #attach
    ec2.attach_volume( :volume_id => vol.volumeId, :instance_id => instanceid, :device => '/dev/sdh')

    puts colorBlue dnsname
  end

end
