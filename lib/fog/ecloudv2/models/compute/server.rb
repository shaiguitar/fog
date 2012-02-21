require 'fog/compute/models/server'

module Fog
  module Compute
    class EcloudV2

      class Server < Fog::Compute::Server

        identity :id
        # attribute :cpu
        # attribute :description
        # attribute :flavor_id,   :aliases => :product, :squash => 'id'
        # attribute :hostname
        # attribute :ips
        # attribute :memory
        # attribute :state,       :aliases => "status"
        # attribute :storage
        # attribute :template
        # attr_accessor :hostname, :password, :lb_applications, :lb_services, :lb_backends
        # attr_writer :private_key, :private_key_path, :public_key, :public_key_path, :username

        def initialize(attributes={})
          super
        end

      end

    end
  end
end
