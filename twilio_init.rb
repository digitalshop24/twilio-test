module TwilioInit
  TWILIO_SID = ENV['account_sid']
  TWILIO_TOKEN = ENV['auth_token']
  TWILIO_NUMBER = ENV['from']

  CARS = ["Ford Focus", "Ford Fiesta", "Ford Mondeo"]

  ROOT_PATH = ENV['ROOT_PATH']

  def valid?(phone_number)
    lookup_client = Twilio::REST::LookupsClient.new(TWILIO_SID, TWILIO_TOKEN)
    begin
      response = lookup_client.phone_numbers.get(phone_number)
      response.phone_number #if invalid, throws an exception. If valid, no problems.
      ['BY', 'RU'].include? response.country_code
    rescue => e
      if e.code == 20404
        return false
      else
        raise e
      end
    end
  end
end