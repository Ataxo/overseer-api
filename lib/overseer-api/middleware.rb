require 'action_dispatch'
require 'overseer-api'

module OverseerApi
  class Middleware
    def self.default_ignore_exceptions
      [].tap do |exceptions|
        exceptions << ActiveRecord::RecordNotFound if defined? ActiveRecord && defined? ActiveRecord::RecordNotFound
        exceptions << AbstractController::ActionNotFound if defined? AbstractController && defined? AbstractController::ActionNotFound
        exceptions << ActionController::RoutingError if defined? ActionController && defined? ActionController::RoutingError
      end
    rescue Exception => e
      puts "Problem with loading Overseer::Middleware error:"
      puts e.message
      []
    end

    def initialize(app, options = {})
      @app, @options = app, options
      @options[:ignore_exceptions] ||= self.class.default_ignore_exceptions
    end

    def call(env)
      @app.call(env)
    rescue Exception => exception
      options = (env['overseer_rails.options'] ||= {})
      options.reverse_merge!(@options)

      unless Array.wrap(options[:ignore_exceptions]).include?(exception.class)
        OverseerApi.error(exception)
      end

      raise exception
    end
  end
end