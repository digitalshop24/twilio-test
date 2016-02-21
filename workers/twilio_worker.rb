require_relative '../config/sidekiq'
class TwilioWorker
  include Sidekiq::Worker
  def perform(phone, name, car)
    client = Twilio::REST::Client.new ENV['account_sid'], ENV['auth_token']
      call = client.account.calls.create(
        from: ENV['from'],
        to: phone,
        url: "#{ROOT_PATH}/connect?name=#{name}&car=#{car}",
        method: 'GET'
      )
  end
end
