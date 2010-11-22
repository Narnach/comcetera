require 'open-uri'
require 'timeout'

class Comcetera
  ERROR_CODES={
    "1"=>"Unknown subscriber",
    "29"=>"Absent subscriber",
    "21"=>"Facility not supported",
    "11"=>"Teleserice not provisioned",
    "13"=>"Call barred",
    "36"=>"System Failure"
  }

  attr_accessor :operator_code, :msisdn
  attr_accessor :error_code, :error_message, :debug

  def initialize(attributes={})
    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  class << self
    attr_accessor :username, :password, :timeout, :retries

    def timeout
      @timeout ||= 2
    end

    def retries
      @retries ||= 2
    end

    def password
      @password || raise("No password set for Comcetera")
    end

    def username
      @username || raise("No username set for Comcetera")
    end

    # Attempt an operator lookup based on msisdn.
    def detect(msisdn)
      attempts = 0
      while attempts <= self.retries
        attempts += 1
        begin
          Timeout::timeout(self.timeout) do
            body=open("http://api.comcetera.com/npl?user=#{self.username}&pass=#{self.password}&msisdn=#{msisdn}").read
            msisdn, operator_code = body.split("\n")[1].split(" ") # 2nd line, last word is the operator hexcode
            unless operator_code.to_s =~ /ERR(\d+)/
              return new(:operator_code => operator_code, :msisdn => msisdn)
            else
              return new(:operator_code => nil, :msisdn => msisdn, :error_code=>operator_code, :error_message=>ERROR_CODES[$1]||"Unknown Error", :debug=>body)
            end
          end
        rescue Timeout::Error, SystemCallError => e
          # ignore
        end
      end
      new(:error_message=>"Timeout from Comcetera", :debug=>"#{self.retries} times no response within #{self.timeout} seconds")
    end

    def setup_fakeweb_response(options={})
      raise "FakeWeb is not defined. Please require 'fakeweb' and make sure the fakeweb rubygem is installed." unless defined?(FakeWeb)
      raise ArgumentError.new("Option missing: :msisdn") unless options[:msisdn]
      raise ArgumentError.new("Option missing: :result") unless options[:result]
      options[:username]||= self.username
      options[:password]||= self.password
      FakeWeb.register_uri :get, "http://api.comcetera.com/npl?user=#{options[:username]}&pass=#{options[:password]}&msisdn=#{options[:msisdn]}", :body=> <<-MSG
QUERYOK
#{options[:msisdn]} #{options[:result]}
ENDBATCH
      MSG
    end
  end

  def ==(other)
    [:operator_code, :msisdn, :error_code, :error_message, :debug].each do |attribute|
      return false unless self.send(attribute) == other.send(attribute)
    end
    true
  end
end
