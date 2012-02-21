require 'fog/core/collection'
require 'fog/ecloudv2/models/compute/server'

module Fog
  module Compute
    class EcloudV2

      class Servers < Fog::Collection

        model Fog::Compute::EcloudV2::Server

        def get(server_id)
        end

        def all
        end


      end
    end
  end
end