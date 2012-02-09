require 'active_support'

for provider, config in compute_providers
  def subscribe(match)
    @events = []
    ActiveSupport::Notifications.subscribe(match) do |*args|
      @events << ActiveSupport::Notifications::Event.new(*args)
    end
  end

  Shindo.tests("Fog::Compute[:#{provider}] | instrumentation", 'instrumentation') do
    if Fog.mocking?
      pending
    else
      tests('basic notification', :instrumentation).returns('fog.connection') do
        subscribe(/fog/)
        compute_params = { :provider => provider, :instrumentor=> ActiveSupport::Notifications }
        begin
          fog = Fog::Compute.new(compute_params)
          fog.servers.all
        rescue
        end
        @events.first.name
      end
    end
  end
end
