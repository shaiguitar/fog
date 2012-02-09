require 'active_support'
require 'pp'
require 'ruby-debug'

# for provider, config in compute_providers
  provider = :aws
  config = compute_providers[:aws]
  def subscribe(match)
    @events = []
    ActiveSupport::Notifications.subscribe(match) do |*args|
      puts 'POW'
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

    tests('basic notification', :instrumentation).returns('fog.request') do
      subscribe(/fog/)
      compute_params = { :provider => provider, :instrumentor=> ActiveSupport::Notifications }
      # debugger
      fog = Fog::Compute.new(compute_params)
      fog.describe_instances
      @events.first.name
    end
  end
