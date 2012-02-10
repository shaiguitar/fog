require 'active_support'
require 'ruby-debug'
for provider, config in compute_providers
  def subscribe(match)
    @events = []
    ActiveSupport::Notifications.subscribe(match) do |*args|
      @events << ActiveSupport::Notifications::Event.new(*args)
    end
  end

  class MyCustomInstrumentor
    class << self
      attr_accessor :events

      def instrument(name, params = {}, &block)
        @events ||= []
        @events << name
        yield if block_given?
      end

    end
  end

  Shindo.tests("Fog::Compute[:#{provider}] | instrumentation", 'instrumentation') do
    if Fog.mocking?
      pending
    else
      tests('basic notification', :instrumentation).returns('fog.connection') do
        subscribe(/fog/)
        compute_params = { :provider => provider,
          :instrumentor_params => {:instrumentor=> ActiveSupport::Notifications} }
        begin
          fog = Fog::Compute.new(compute_params)
          fog.servers.all
        rescue
        end
        @events.first.name
      end

      tests('works without active_support if it has an instrument method').returns(true) do
        compute_params = { :provider => provider,
          :instrumentor_params => {:instrumentor=> MyCustomInstrumentor} }
        begin
          fog = Fog::Compute.new(compute_params)
          fog.servers.all
        rescue
        end
        !!MyCustomInstrumentor.events.first.match(/^fog.connection/)
      end

      tests('includes request parameters')
      tests('event named for request time')
      tests('reflects request duration')
    end
  end
end
