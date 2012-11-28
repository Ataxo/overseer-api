# -*- encoding : utf-8 -*-

module OverseerApi

  ####################################################
  # CONFIG
  ####################################################
  @config = {
    url: "http://overseer.ataxo.com",
    version: :v1,
    api_name: "SlimApi.name = 'YOUR APPLICATION NAME'",
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

  def self.send type, exception, args = {}, tags = "", raised_at = Time.now
    request type, exception, args, tags, raised_at
  end

  def self.log exception, args = {}, tags = "", raised_at = Time.now
    request :log, exception, args, tags, raised_at
  end

  def self.error exception, args = {}, tags = "", raised_at = Time.now
    request :error, exception, args, tags, raised_at
  end

  def self.warn exception, args = {}, tags = "", raised_at = Time.now
    request :warn, exception, args, tags, raised_at
  end

  def self.info exception, args = {}, tags = "", raised_at = Time.now
    request :info, exception, args, tags, raised_at
  end

  def self.request type, exception, args, tags, raised_at

    params = {
      app_name: OverseerApi.app_name,
      klass: exception.class.to_s,
      message: exception.message,
      backtrace: exception.backtrace.to_a.join("\n"),
      arguments: args,
      raised_at: raised_at,
      tags: tags,
      error_type: type,
    }

    curl = Curl::Easy.new 
    curl.headers["Content-Type"] = "application/json"
    curl.verbose = false
    curl.resolve_mode = :ipv4

    #set right url dependetnly on verb
    curl.url = OverseerApi.api_url

    puts Yajl::Encoder.encode(params)
    curl.post_body = Yajl::Encoder.encode(params)

    curl.http "POST"

    puts response = Yajl::Parser.parse(curl.body_str)
  rescue Exception => e 
    puts "Problem with sending data to Overseer!"
    puts e.class
    puts e.message
    puts e.backtrace.join("\n")
  end

end