# Overseer-API

Accessing Overseer and send easily exceptions for your application

## Instalation

Just in console

``` ruby
gem install overseer-api
```

Or put into Gemfile

``` ruby
gem "overseer-api"
#or
gem "overseer-api", :git => "git://github.com/Ataxo/overseer-api.git"
```

and somewhere before use (not rails - they will require gem automaticaly)
``` ruby
require "overseer-api"
```

## Initialization

Setup your config values 
* Rails - put it into config/initializers/overseer.rb
* Sinatra - somewher in initialization

``` ruby
OverseerApi.app_name = "Your app name"

#optional settings
OverseerApi.version = :v1
#default is :v1

#url where is slim api located
OverseerApi.url = "http://overseer.ataxo.com"
```

## Working with Gem

### In your application
When some exception came, you can log it by calling method:
``` ruby
OverseerApi.send TYPE, EXECEPTION, ARGUMENTS, TAGS, RAISED_AT
TYPE = [:error, :warn, :info]
EXCEPTION = subclass of Exception
ARGUMENTS = nil, array or hash
TAGS = custom text (can be splitted by comma)
RAISED_AT = Time when exceptin been raised
```

example: 

``` ruby
args = {foo: "bar"}
begin
  raise ArgumentError, "Some message"
rescue Exception => e
  OverseerApi.log :error, e, args, "my bad error"
end
#or by type:

begin
  raise ArgumentError, "Some message"
rescue Exception => e
  OverseerApi.error e, args
  #optionaly
  OverseerApi.log e, args
  OverseerApi.info e, args
  OverseerApi.warn e, args
end
```

if you don't rescuing from begin/rescue block and you want to send log to Overseer you can use:
``` ruby
#string as name of error
OverseerApi.info "MyCustomClass", {foo:"bar"}

#or use hash with custom message and backtrace
OverseerApi.info {klass: "MyCustomClass", message: "My message"}, {foo:"bar"}
```

### In your Resque

You need to use [resque-scheduler](https://github.com/bvandenbos/resque-scheduler)
and in your `schedule.yml` add lines:
``` yml
send_failed_to_overseer:
  cron: "*/10 * * * *"
  class: OverseerApi
  queue: overseer #change this by your own application specific workers
  #ensure that at least one worker is working on this queue
  description: "Send failed jobs to Overseer"
```

## Copyright

Copyright (c) 2012 Ondrej Bartas. See LICENSE.txt for
further details.