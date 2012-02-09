Shindo.tests('Fog connection', 'core') do
  class SimpleInstrumentor
    class << self
      attr_accessor :events

      def instrument(name, params = {}, &block)
        @events ||= []
        @events << name
        yield if block_given?
      end

    end
  end

  before do
    @fog_was_mocked = Fog.mock?
    Fog.unmock! if @fog_was_mocked
  end

  after do
    Fog.mock! if @fog_was_mocked
  end

  tests('Fog connections') do

    tests('Creates a connection').returns(true) do
      Fog::Connection.new("http://fake.url", false, {}).is_a?(Fog::Connection)
    end

    tests('Also accepts an instrumentor in the contructor').returns('chutney') do
      connection = Fog::Connection.new("http://fake.url", false, {},
          {:instrumentor_name => "chutney", :instrumentor => SimpleInstrumentor})
      begin
        connection.request({})
      rescue Excon::Errors::SocketError
      end
      SimpleInstrumentor.events.first
    end

  end

end
