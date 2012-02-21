module Fog
  module Compute
    class EcloudV2
      class Real

        def get_time(options={})
          request(
            :method => "GET",
            :path   => "time/"
          )
        end

      end
    end
  end
end