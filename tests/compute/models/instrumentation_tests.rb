require 'active_support'
require 'pp'

for provider, config in compute_providers
  def subscribe(match)
    @events = []
    ActiveSupport::Notifications.subscribe(match) do |*args|
      @events << ActiveSupport::Notifications::Event.new(*args)
    end
  end

  Shindo.tests("Fog::Compute[:#{provider}] | instrumentation", 'instrumentation') do
    if Fog.mocking? && !config[:mocked]
      before do
        Excon.mock = true
      end
    end

    after do
      Excon.mock = false
    end

    tests('basic notification', :instrumentation).returns('something') do
      subscribe(/fog/)
      compute_params = { :provider => provider, :instrumentor=> ActiveSupport::Notifications }
      Fog::Compute.new(compute_params).servers
      @events.first.name
    end
  end
end