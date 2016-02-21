require "rubygems"
require "sinatra"

require File.expand_path '../config/env.rb', __FILE__
require File.expand_path '../config/sidekiq.rb', __FILE__
require File.expand_path '../twilio.rb', __FILE__

run TwilioTest
