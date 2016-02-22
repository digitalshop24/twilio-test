require 'twilio-ruby'
require_relative '../config/sidekiq'
require_relative '../twilio_init'
class TwilioWorker
  include TwilioInit
  include Sidekiq::Worker
  def perform(phone, dealer_phone, name, car)
    client = Twilio::REST::Client.new TWILIO_SID, TWILIO_TOKEN
      call = client.account.calls.create(
        from: ENV['from'],
        to: dealer_phone,
        url: URI.encode("#{ROOT_PATH}/connect?phone=#{phone}&dealer_phone=#{dealer_phone}&name=#{name}&car=#{car}"),
        method: 'GET'
      )
    File.open('../log/calls.log', 'a') { |file| file.write("#{Time.now} | To: #{call.to} | Sid: #{call.sid} !!delayed call!!\n\r") }
  end
end
