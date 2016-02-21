require 'sinatra'
require 'twilio-ruby'
require 'pry'
require 'open-uri'

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

class TwilioTest < Sinatra::Base
  enable :sessions
  include TwilioInit

  get '/' do
    erb :index
  end

  post '/call' do
    phone = session[:phone] = params[:phone]
    session[:dealer_phone] = params[:dealer_phone]
    session[:name] = params[:name]
    session[:car] = params[:car]

    if valid? phone
      url = ''
      if (phone != '+375292595346')
        url = URI.encode("#{ROOT_PATH}/connect")
      else
        url = URI.encode("#{ROOT_PATH}/sasha_action")
      end
      client = Twilio::REST::Client.new TWILIO_SID, TWILIO_TOKEN
      call = client.account.calls.create(
        from: TWILIO_NUMBER,
        to: phone,
        url: url,
        method: 'GET'
      )
      @msg ='Спасибо. Вам скоро позвонят.'
      File.open('log/calls.log', 'a') { |file| file.write("#{Time.now} | To: #{call.to} | Sid: #{call.sid}\n\r") }
    else
      @msg = 'Неверный номер'
      File.open('log/calls.log', 'a') { |file| file.write("#{Time.now} === BAD NUMBER: #{phone} ===\n\r") }
    end
    erb :call
  end

  get '/connect' do
    name = params[:name] || session[:name]
    car = params[:car] || session[:car]
    response = Twilio::TwiML::Response.new do |r|
      r.Say "Здравствуйте, #{name}! Вы записались на тест-драйв автомобиля #{CARS[car.to_i]}", voice: 'alice', language: 'ru-RU'
      r.Gather numDigits: '1', action: "/menu_select", method: 'GET' do |g|
        g.Say "Нажмите один, если хотите, чтобы вас соединили с дилером. Два - если не хотите.", voice: 'alice', language: 'ru-RU'
      end
      r.Say "Что-то пошло не так", voice: 'alice', language: 'ru-RU'
    end
    response.text
  end

  get '/menu_say' do
    Twilio::TwiML::Response.new do |r|
      r.Gather numDigits: '1', action: "/menu_select", method: 'GET' do |g|
        g.Say "Нажмите один, если хотите, чтобы вас соединили с дилером. Два - если не хотите.", voice: 'alice', language: 'ru-RU'
      end
    end.text
  end

  get '/sasha_action' do
    response = Twilio::TwiML::Response.new do |r|
      r.Say "Привет, Саша. Ты пидор!", voice: 'alice', language: 'ru-RU'
    end
    response.text
  end

  get '/menu_select' do
    user_selection = params[:Digits]

    response = Twilio::TwiML::Response.new do |r|
      phrase = ''
      case user_selection
      when "1"
        r.Say "Ожидайте. Сейчас вас соединят с дилером.", voice: 'alice', language: 'ru-RU'
        r.Dial session[:dealer_phone]
        r.Say 'Ошибка набора либо дилер повесил трубку. Всего доброго.', voice: 'alice', language: 'ru-RU'
      when "2"
        phrase = "Жаль, что вы передумали."
        TwilioWorker.perform_in(1.minutes, session[:phone], session[:name], session[:car])
      else
        redirect '/menu_say'
      end
      r.Hangup
    end
    response.text
  end
end
