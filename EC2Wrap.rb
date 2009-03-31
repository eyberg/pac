require 'EC2'
require 'Colorify'

class EC2Wrap
  include Colorify

  def provision

    hash = File.open('ec2.yml') do |f| YAML.load f end

    ec2 = EC2::Base.new(:access_key_id => hash["access_key"], :secret_access_key => hash["secret_key"])

    # ubuntu jaunty jakolope
    ni = ec2.run_instances(:image_id => "ami-b31ff8da")
    rid =  ni["reservationId"]

    instance = ec2.describe_instances(:reservationID => rid)
    puts colorBlue instance.reservationSet.item[0].instancesSet.item[0].dnsName
  end

end
