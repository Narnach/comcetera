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
      nil
    end
  end
end
