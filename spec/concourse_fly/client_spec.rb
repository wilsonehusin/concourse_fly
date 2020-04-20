module ConcourseFly
  RSpec.describe Client do
    context ".validate_target!" do
      subject { Client.new "https://wings.pivotal.io" }
      context "when target matches" do
        it "returns true" do
          allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
            double("response", status: 200, body: '{"external_url": "https://wings.pivotal.io"}')
          )
          expect(subject.validate_target!).to eq true
        end
      end
      context "when target does not match" do
        it "raises TargetError" do
          allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
            double("response", status: 200, body: '{"external_url": "https://wingo.pivotal.io"}')
          )
          expect { subject.validate_target! }.to raise_error TargetError
        end
      end
      context "when response is not understandable" do
        it "raises ResponseError" do
          allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
            double("response", status: 200, body: '{"external_url": "https://wings.pivotal.io"')
          )
          expect { subject.validate_target! }.to raise_error ResponseError
        end
      end
      context "when Faraday raises arbitrary error" do
        it "raises FlyError" do
          allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::Error, nil)
          expect { subject.validate_target! }.to raise_error FlyError
        end
      end
    end
  end
end
