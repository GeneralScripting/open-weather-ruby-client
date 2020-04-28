# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenWeather::Client do
  before do
    OpenWeather::Config.reset
  end
  context 'with defaults' do
    let(:client) { described_class.new }
    context '#initialize' do
      it 'implements endpoint' do
        expect(client.endpoint).to_not be nil
      end
      it 'includes default http configuration' do
        expect(client.user_agent).to eq "OpenWeather Ruby Client/#{OpenWeather::VERSION}"
      end
      it 'sets user-agent' do
        expect(client.user_agent).to eq OpenWeather::Config.user_agent
        expect(client.user_agent).to include OpenWeather::VERSION
      end
      (OpenWeather::Config::ATTRIBUTES - [:logger]).each do |key|
        it "sets #{key}" do
          expect(client.send(key)).to eq OpenWeather::Config.send(key)
        end
      end
    end
  end
  context 'with custom settings' do
    context '#initialize' do
      OpenWeather::Config::ATTRIBUTES.each do |key|
        context key.to_s do
          let(:client) { described_class.new(key => 'custom') }
          it "sets #{key}" do
            expect(client.send(key)).to_not eq OpenWeather::Config.send(key)
            expect(client.send(key)).to eq 'custom'
          end
        end
      end
    end
  end
  context 'global config' do
    let(:client) { described_class.new }
    context 'user-agent' do
      before do
        OpenWeather::Client.configure do |config|
          config.user_agent = 'custom/user-agent'
        end
      end
      context '#initialize' do
        it 'sets user-agent' do
          expect(client.user_agent).to eq 'custom/user-agent'
        end
        it 'creates a connection with the custom user-agent' do
          expect(client.send(:connection).headers).to include(
            'Accept' => 'application/json; charset=utf-8',
            'User-Agent' => 'custom/user-agent'
          )
        end
      end
    end
    context 'proxy' do
      before do
        OpenWeather::Client.configure do |config|
          config.proxy = 'http://localhost:8080'
        end
      end
      context '#initialize' do
        it 'sets proxy' do
          expect(client.proxy).to eq 'http://localhost:8080'
        end
        it 'creates a connection with the proxy' do
          expect(client.send(:connection).proxy.uri.to_s).to eq 'http://localhost:8080'
        end
      end
    end
    context 'SSL options' do
      before do
        OpenWeather::Client.configure do |config|
          config.ca_path = '/ca_path'
          config.ca_file = '/ca_file'
        end
      end
      context '#initialize' do
        it 'sets ca_path and ca_file' do
          expect(client.ca_path).to eq '/ca_path'
          expect(client.ca_file).to eq '/ca_file'
        end
        it 'creates a connection with ssl options' do
          ssl = client.send(:connection).ssl
          expect(ssl.ca_path).to eq '/ca_path'
          expect(ssl.ca_file).to eq '/ca_file'
        end
      end
    end
    context 'logger option' do
      let(:logger) { Logger.new(STDOUT) }
      before do
        OpenWeather::Client.configure do |config|
          config.logger = logger
        end
      end
      context '#initialize' do
        it 'sets logger' do
          expect(client.logger).to eq logger
        end
        it 'creates a connection with a logger' do
          expect(client.send(:connection).builder.handlers).to include ::Faraday::Response::Logger
        end
      end
    end
    context 'timeout options' do
      before do
        OpenWeather::Client.configure do |config|
          config.timeout = 10
          config.open_timeout = 15
        end
      end
      context '#initialize' do
        it 'sets timeout and open_timeout' do
          expect(client.timeout).to eq 10
          expect(client.open_timeout).to eq 15
        end
        it 'creates a connection with timeout options' do
          conn = client.send(:connection)
          expect(conn.options.timeout).to eq 10
          expect(conn.options.open_timeout).to eq 15
        end
      end
    end
  end
end
