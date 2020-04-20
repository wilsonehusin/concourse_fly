module ConcourseFly
  RSpec.describe EndpointResolver do
    subject { EndpointResolver.new "v5.8.0" }
    context "#fetch" do
      context "when cached file is available" do
        before :each do
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:read).and_return(<<~YAML)
            ---
            foo: bar
          YAML
        end
        it "retrieves from cached file and doesn't make HTTP request" do
          expect(subject.fetch).to eq({"foo" => "bar"})
        end
        it "does not make HTTP get" do
          expect(Faraday).not_to receive(:get)
          subject.fetch
        end
      end
      context "when cached file is unavailable" do
        it "retrieves from Concourse repository" do
          allow(File).to receive(:exist?).and_return(false)
          expect(Faraday).to receive(:get).and_return(
            double("response", body: '{Path: "/api/v1/info", Method: "GET", Name: "GetInfo"},')
          )
          expect(subject.fetch).to eq({"GetInfo" => {"path" => "/api/v1/info", "method" => "GET"}})
        end
      end
      context "when ignore_cache is true" do
        it "retrieves from Concourse repository" do
          allow(File).to receive(:exist?).and_return(true)
          expect(Faraday).to receive(:get).and_return(
            double("response", body: '{Path: "/api/v1/info", Method: "GET", Name: "GetInfo"},')
          )
          expect(File).not_to receive(:read)
          expect(subject.fetch(false)).to eq({"GetInfo" => {"path" => "/api/v1/info", "method" => "GET"}})
        end
      end
    end
  end
end
