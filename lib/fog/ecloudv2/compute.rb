module Fog
  module Compute
    class EcloudV2 < Fog::Service

      API_URL = "services.enterprisecloud.terremark.com"

      #### Credentials
      #requires
      recognizes    :ecloudv2_password, :ecloudv2_username, :ecloudv2_version, :ecloudv2_api_key, :ecloudv2_versions_uri, :ecloudv2_host, :ecloudv2_versions_uri, :ecloudv2_access_key, :ecloudv2_private_key

      #### Models
      model_path    'fog/ecloudv2/models/compute'
      model         :server
      collection    :servers

      #### Requests
      request_path  'fog/ecloudv2/requests/compute'
      request       :get_versions
      request       :get_time
      request       :get_organizations


      class Mock
        def self.data
          @data ||= Hash.new do |hash, key|
            hash[key] = {}
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          @ecloudv2_api_key = options[:ecloudv2]
        end

        def data
          self.class.data[@ecloudv2_api_key]
        end

        def reset_data
          self.class.data.delete(@ecloudv2_api_key)
        end
      end


      class Real

        attr_reader :authentication_method, :version

        def initialize(options     = {})
          @connection_options      = options[:connection_options]  || {}
          @host                    = options[:ecloudv2_host]       || API_URL
          @persistent              = options[:persistent]          || false
          @version                 = options[:ecloudv2_version]    || "2011-10-01"
          @authentication_method   = :cloud_api_auth
          @access_key              = options[:ecloudv2_access_key]
          @private_key             = options[:ecloudv2_private_key]
          if @private_key.nil?
            @authentication_method = :basic_auth
            @username              = options[:ecloudv2_username]
            @password              = options[:ecloudv2_password]
            if @username.nil? || @password.nil?
              raise RuntimeError, "No credentials (cloud auth, or basic auth) passed!"
            end
          else
            @hmac                  = Fog::HMAC.new("sha256", @private_key)
          end
          @connection              = Fog::Connection.new("https://#{@host}:#{443}", @persistent, @connection_options)
        end

        def request(params = {})
          params[:path]     = params[:path]
          params[:expects]  = [200, 201, 204]
          params[:headers]  ||= {}
          params[:method]   ||= "GET"
          set_extra_headers_for(params)
          begin
            response = @connection.request(params)
          rescue Excon::Errors::HTTPStatusError => error
            raise case error
            when Excon::Errors::NotFound
              Fog::Compute::EcloudV2::NotFound.slurp(error)
            else
              error
            end
          end
          response
        end

        private

        # if Authorization and x-tmrk-authorization are used, the x-tmrk-authorization takes precendence.
        def set_extra_headers_for(params)
         maor_headers = {
           'Accept'             => 'application/xml',
           'x-tmrk-version'     => @version,
           'Date'               => Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT"),
           'x-tmrk-date'        => Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")
         }
         params[:headers].merge!(maor_headers)
         if params[:method]=="POST" || params[:method]=="PUT"
           params[:headers].merge!({"Content-Type" => 'application/xml'})
         end
         if params[:body]
            params[:headers].merge!({"x-tmrk-contenthash" => "Sha256 #{Base64.encode64(Digest::SHA2.digest(params[:body].to_s))}"})
         end
         if @authentication_method == :basic_auth
           params[:headers].merge!({'Authorization' => "Basic #{Base64.encode64(@username+":"+@password).delete("\r\n")}"})
         elsif @authentication_method == :cloud_api_auth
           params[:headers].merge!({
             "Authorization" => %{CloudApi AccessKey="#{@access_key}" SignatureType="HmacSha256" Signature="#{cloud_api_signature(params).chomp}"}
           })
         end
         params
        end

        def cloud_api_signature(params)
          verb                   = params[:method].upcase
          headers                = params[:headers]
          path                   = params[:path]
          canonicalized_headers  = canonicalize_headers(headers)
          canonicalized_resource = canonicalize_resource(path)
          string                 = String.new
          string << verb << "\n"
          string << headers['Content-Length'].to_s  << "\n"
          string << headers['Content-Type'].to_s    << "\n"
          string << headers['Date'].to_s            << "\n"
          string << canonicalized_headers           << "\n"
          string << canonicalized_resource          << "\n"
          Base64.encode64(@hmac.sign(string))
        end



        # section 5.6.3.2 in the ~1000 page pdf spec
        def canonicalize_headers(headers)
          tmp = headers.inject({}) {|ret, h| ret[h.first.downcase] = h.last if h.first.match(/^x-tmrk/i) ; ret }
          tmp.reject! {|k,v| k == "x-tmrk-authorization" }
          tmp = tmp.sort.map{|e| "#{e.first}:#{e.last}" }.join("\n")
          tmp
        end

        # section 5.6.3.3 in the ~1000 page pdf spec
        def canonicalize_resource(path)
          uri, query_string = path.split("?")
          return uri if query_string.nil?
          query_string_pairs = query_string.split("&").sort.map{|e| e.split("=") }
          tm_query_string = query_string_pairs.map{|x| "#{x.first.downcase}:#{x.last}" }.join("\n")
          "#{uri.downcase}\n#{tm_query_string}\n"
        end

      end


    end
  end
end
