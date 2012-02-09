require 'active_support'

module Fog
  class Connection

    def initialize(url, persistent=false, params={})
      @excon = Excon.new(url, params)
      @persistent = persistent
    end

    def request(params, &block)
      unless @persistent
        reset
      end
      unless block_given?
        if (parser = params.delete(:parser))
          body = Nokogiri::XML::SAX::PushParser.new(parser)
          block = lambda { |chunk, remaining, total| body << chunk }
        end
      end

      response = nil
      ActiveSupport::Notifications.instrument('fog.connection', params) do
        response = @excon.request(params, &block)
      end

      if parser
        body.finish
        response.body = parser.response
      end

      response
    end

    def reset
      @excon.reset
    end

  end
end
