# -*- encoding : utf-8 -*-

module OverseerApi

  ####################################################
  # CONFIG
  ####################################################
  @config = {
    url: "http://overseer.ataxo.com",
    version: :v1,
    app_name: "SlimApi.name = 'YOUR APPLICATION NAME'",
  }

  def self.url= url
    @config[:url] = url
  end

  def self.url
    @config[:url]
  end

  def self.version= version
    @config[:version] = version
  end

  def self.version
    @config[:version]
  end

  def self.app_name= app_name
    @config[:app_name] = app_name
  end

  def self.app_name
    @config[:app_name]
  end

  def self.config
    @config
  end

  def self.config= conf
    @config.merge!(conf)
  end

  def self.api_url
    "#{@config[:url]}/api/#{@config[:version]}/app_error/#{@config[:app_name]}"
  end

  ####################################################
  # CALLING Overseer API
  ####################################################

  def self.send_exception type, exception, args = {}, tags = "", raised_at = Time.now
    api_request type, exception, args, tags, raised_at
  end

  def self.log exception, args = {}, tags = "", raised_at = Time.now
    api_request :log, exception, args, tags, raised_at
  end

  def self.error exception, args = {}, tags = "", raised_at = Time.now
    api_request :error, exception, args, tags, raised_at
  end

  def self.warn exception, args = {}, tags = "", raised_at = Time.now
    api_request :warn, exception, args, tags, raised_at
  end

  def self.info exception, args = {}, tags = "", raised_at = Time.now
    api_request :info, exception, args, tags, raised_at
  end

  def self.api_request type, exception, args, tags, raised_at
    params = {
      arguments: args,
      raised_at: raised_at,
      tags: tags,
      error_type: type,
    }
    if exception.is_a?(Exception)
      api_request_with_args(params.merge({
        klass: exception.class.to_s,
        message: exception.message,
        backtrace: exception.backtrace.to_a.join("\n"),
      }))
    elsif exception.is_a?(Hash)
      api_request_with_args(params.merge({
        klass: ("#{exception[:klass]}" rescue "not_set"),
        message: ("#{exception[:message]}." rescue "not_set"),
        backtrace: ("#{exception[:backtrace]}." rescue "not_set"),
      }))
    else 
      api_request_with_args(params.merge({
        klass: exception.to_s,
        message: "not_set",
        backtrace: "not_set",
      }))
    end
  end

  def self.api_request_with_args params

    curl = Curl::Easy.new 
    curl.headers["Content-Type"] = "application/json"
    curl.verbose = false
    curl.resolve_mode = :ipv4

    #set right url dependetnly on verb
    curl.url = OverseerApi.api_url

    #set post body + add app name
    curl.post_body = Yajl::Encoder.encode(
      params.merge(
        app_name: OverseerApi.app_name
      )
    )
    curl.http "POST"

    response = Yajl::Parser.parse(curl.body_str)
  rescue Exception => e 
    puts "Problem with sending data to Overseer!"
    puts e.class
    puts e.message
    puts e.backtrace.join("\n")
  end

  def self.perform args = {}
    #get count of all failed jobs
    count = Resque::Failure.count
    
    #get all failed jobs
    Resque::Failure.count.times do |i|
      begin
        fail = Resque::Failure.all(i, 1)

        #call request to Overseer for every failed job separately
        api_request_with_args({
          klass: fail["exception"],
          message: fail["error"],
          backtrace: fail["backtrace"].join("\n"),
          arguments: fail["payload"],
          tags: fail["queue"],
          error_type: :warn,
          raised_at: fail["failed_at"],
        })
      rescue
        #call request to Overseer for every failed job separately
        api_request_with_args({
          klass: "ResqueError",
          message: "some wierd error in resque",
          backtrace: "Look at arguments",
          arguments: {job: Resque.redis.lindex("resque:failed", i)},
          error_type: :warn,
          raised_at: Time.now,
        })
      end
    end
    #clear all Failures!
    Resque::Failure.clear

  end

end