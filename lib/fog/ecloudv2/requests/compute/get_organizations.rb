module Fog
  module Compute
    class EcloudV2
      class Real

        def get_organizations(options={})
          request(
            :method => "GET",
            :path   => "/cloudapi/ecloud/organizations/"
          )
        end

      end
    end
  end
end