require 'pry'
require 'yaml'

Shindo.tests("Fog::Compute[:ecloudv2]", ['ecloudv2']) do

  before do

    config =  YAML.load(File.read(File.expand_path('~/.fog')))

    @access_key             = config[:default][:ecloudv2_access_key]
    @private_key            = config[:default][:ecloudv2_private_key]
    @version                = "2011-10-01"
    @username               = config[:default][:ecloudv2_username]
    @password               = config[:default][:ecloudv2_password]
    @ecloudv2_cloud_auth    = Fog::Compute.new(:provider => 'ecloudv2',
                                :ecloudv2_access_key => @access_key,
                                :ecloudv2_private_key => @private_key,
                                :ecloudv2_version => '2011-10-01')
    @ecloudv2_basic_auth  = Fog::Compute.new(:provider => 'ecloudv2',
                                :ecloudv2_version => '2011-10-01',
                                :ecloudv2_username => @username,
                                :ecloudv2_password => @password)
    @ecloudv2_both_auth  = Fog::Compute.new(:provider => 'ecloudv2',
                                :ecloudv2_version => '2011-10-01',
                                :ecloudv2_username => @username,
                                :ecloudv2_password => @password,
                                :ecloudv2_access_key => @access_key,
                                :ecloudv2_private_key => @private_key)
# require 'activesupport'
# require 'pp'
# include ActiveSupport::CoreExtensions::Hash
# organizations_hash = Hash.from_xml(@ecloudv2_basic_auth.get_organizations.body)
# pp organizations_hash

    @default_params            = {}
    @default_params[:expects]  = [200, 204]
    @default_params[:path]     = "/"
    @default_params[:headers]  = {}
    @default_params[:method]   = "GET"
  end

  tests("Defaults to cloud_api_authentication").returns(:cloud_api_auth) do
    @ecloudv2_cloud_auth.authentication_method
  end

  tests("Will use basic auth if no private key is passed, but that has basic auth").returns(:basic_auth) do
    @ecloudv2_basic_auth.authentication_method
  end

  tests("Will use cloud auth if all the credentials are passed").returns(:cloud_api_auth) do
    @ecloudv2_both_auth.authentication_method
  end

  tests("Will explode if neither basic auth or cloud_api auth creds are passed").raises(RuntimeError) do
    Fog::Compute.new(:provider => 'ecloudv2', :ecloudv2_version => '2011-10-01')
  end

  tests("Will default to 2011-10-01 r2_11 as the api version if nothing else was passed").returns("2011-10-01") do
    Fog::Compute.new(:provider => 'ecloudv2', :ecloudv2_username => @username, :ecloudv2_password => @password).version
  end

  tests("It will create the authorization header according to the authenication method") do
    tests("For basic auth").returns(Array) do
      @ecloudv2_basic_auth.__send__(:set_extra_headers_for, @default_params)[:headers]["Authorization"].split(%r{\n}).grep(/Basic/).class
    end
    tests("And for cloud auth").returns(Array) do
      @ecloudv2_cloud_auth.__send__(:set_extra_headers_for, @default_params)[:headers]["Authorization"].split(%r{\n}).grep(/CloudApi/).class
    end
  end

  tests("it can make successful authenicated requests") do
    tests("For basic auth").returns(200) do
      @ecloudv2_basic_auth.get_organizations.status
    end
    tests("For cloud auth").returns(200) do
      @ecloudv2_cloud_auth.get_organizations.status
    end

  end



end
