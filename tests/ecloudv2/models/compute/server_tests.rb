Shindo.tests("Fog::Compute[:ecloudv2] | server", ['ecloudv2']) do

  @instance = Fog::Compute[:ecloudv2].servers.new

  [:something].each do |association|
    responds_to(association)
  end

  @instance.destroy

end
