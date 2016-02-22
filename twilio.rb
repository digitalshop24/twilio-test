require 'sinatra'
require 'twilio-ruby'
require 'pry'
require 'open-uri'
require 'active_support/all'
require_relative 'workers/twilio_worker'
require_relative 'twilio_init'

class TwilioTest < Sinatra::Base
  include TwilioInit
  before do
    @phone = params[:phone]
    @dealer_phone = params[:dealer_phone]
    @name = params[:name]
    @car = params[:car]
    @user_selection = params[:Digits]
  end

  get '/' do
    erb :index
  end

  post '/call' do
    if valid? @phone
      url = ''
      if (@phone != '+375292595346')
        url = "#{ROOT_PATH}/connect?#{params.to_query}"
      else
        url = "#{ROOT_PATH}/sasha_action"
      end
      client = Twilio::REST::Client.new TWILIO_SID, TWILIO_TOKEN
      call = client.account.calls.create(
        from: TWILIO_NUMBER,
        to: @phone,
        url: url,
        method: 'GET'
      )
      @msg ='Спасибо. Вам скоро позвонят.'
      File.open('log/calls.log', 'a') { |file| file.write("#{Time.now} | To: #{call.to} | Sid: #{call.sid}\n\r") }
    else
      @msg = 'Неверный номер'
      File.open('log/calls.log', 'a') { |file| file.write("#{Time.now} === BAD NUMBER: #{@phone} ===\n\r") }
    end
    erb :call
  end

  get '/connect' do
    response = Twilio::TwiML::Response.new do |r|
      r.Say "Здравствуйте, #{@name}! Вы записались на тест-драйв автомобиля #{CARS[@car.to_i]}", voice: 'alice', language: 'ru-RU'
      r.Gather numDigits: '1', action: "/menu_select?#{params.to_query}", method: 'GET' do |g|
        g.Say "Нажмите один, если хотите, чтобы вас соединили с дилером. Два - если не хотите.", voice: 'alice', language: 'ru-RU', loop: 3
      end
      r.Say "Что-то пошло не так", voice: 'alice', language: 'ru-RU'
    end
    response.text
  end

  get '/menu_say' do
    Twilio::TwiML::Response.new do |r|
      r.Gather numDigits: '1', action: "/menu_select?#{params.to_query}", method: 'GET' do |g|
        g.Say "Нажмите один, если хотите, чтобы вас соединили с дилером. Два - если не хотите.", voice: 'alice', language: 'ru-RU', loop: 3
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
    response = Twilio::TwiML::Response.new do |r|
      case @user_selection
      when "1"
        r.Say "Ожидайте. Сейчас вас соединят с дилером.", voice: 'alice', language: 'ru-RU'
        r.Dial @dealer_phone
        # r.Say 'Ошибка набора либо дилер повесил трубку. Всего доброго.', voice: 'alice', language: 'ru-RU'
      when "2"
        TwilioWorker.perform_in(60, @phone, @dealer_phone, @name, @car)
        phrase = "Жаль, что вы передумали."
      else
        redirect "/menu_say?#{params.to_query}"
      end
      r.Hangup
    end
    response.text
  end
end
