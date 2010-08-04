require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

FakeWeb.register_uri :get, 'http://api.comcetera.com/npl?user=username&pass=password&msisdn=31612345678', :body=> <<-MSG
QUERYOK
31612345678 12345
ENDBATCH
MSG

describe "Comcetera" do
  before(:all) do
    Comcetera.username = "username"
    Comcetera.password = "password"
  end

  describe "detect" do
    it "should return a new Comcetera instance" do
      @comcetera = Comcetera.detect(31612345678)
      @comcetera.should be_instance_of(Comcetera)
    end

    it "should retry after a timeout and return nil when it still fails" do
      3.times {Timeout.should_receive(:timeout).with(2).and_raise(Timeout::Error)}
      @comcetera = Comcetera.detect(31612345678)
      @comcetera.should be_nil
    end

    describe "the returned Comcetera instance" do
      before(:each) do
        @comcetera = Comcetera.detect(31612345678)
      end

      it "should contain the returned operator code" do
        @comcetera.operator_code.should == "12345"
      end

      it "should contain the returned msisdn" do
        @comcetera.msisdn.should == "31612345678"
      end
    end
  end
end
