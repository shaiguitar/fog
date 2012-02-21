module Fog
  module Compute
    class EcloudV2
      class Real

        def get_versions(options={})
          request(
            :method => "GET",
            :path   => "versions/"
          )
        end

      end
    end
  end
end
