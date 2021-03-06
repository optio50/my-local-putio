module MyLocalPutio
  class PutioCli
    ROOT = "https://api.put.io/v2/"
    attr_reader :configuration, :endpoint, :http, :logger

    def initialize(configuration)
      @configuration = configuration
      @logger = configuration.logger
      @endpoint = URI(ROOT)
      setup_connection
    end

    def get_files(parent_id=nil)
      args = parent_id ? {parent_id: parent_id, sort: "NAME_DESC"} : {sort: "DATE_DESC"}
      get("files/list", args)
    end

    def delete_file(id)
      args = {file_ids: id}
      post("files/delete", args)
    end

    def get_subtitles(id)
      get("files/#{id}/subtitles")
    end

    def get_download_url(id)
      get("files/#{id}/url")
    end

    protected

    def http_library
      if @configuration.socks_enabled?
        Net::HTTP::SOCKSProxy(@configuration.socks_host, @configuration.socks_port)
      else
        Net::HTTP
      end
    end

    def setup_connection
      @http = http_library.new(@endpoint.host, @endpoint.port)
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    def get(path, args={})
      url = to_url(path)
      url.query = URI.encode_www_form to_args(args)
      req = Net::HTTP::Get.new(url.request_uri)
      logger.debug "GET #{url}"
      as_json http.request(req)
    end

    def post(path, args={})
      url = to_url(path)
      args = to_args(args)
      logger.debug "POST #{url} -- #{args.inspect}"
      req = Net::HTTP::Post.new(url)
      req.set_form_data(args)
      as_json http.request(req)
    end

    def to_url(path)
      url = endpoint.dup
      url.path += path
      url
    end

    def to_args(args={})
      ret = {}
      args.each_pair do |k,v|
        ret[k.to_s] = v
      end
      args["oauth_token"] = configuration.token
      args
    end

    def as_json(res)
      raise "woot? #{res.inspect}" unless res.is_a?(Net::HTTPSuccess)
      YAML.load res.body
    end
  end
end
