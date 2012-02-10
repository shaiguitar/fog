module Fog
  class Connection

    def initialize(url, persistent=false, connection_params={}, instrumentor_params={})
      @excon = Excon.new(url, connection_params)
      @persistent = persistent
      @instrumentor = instrumentor_params[:instrumentor]
      @instrumentor_name = instrumentor_params[:instrumentor_name] || 'fog.connection'
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
      if @instrumentor
        @instrumentor.instrument(@instrumentor_name, params) do
          response = @excon.request(params, &block)
        end
      else
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
