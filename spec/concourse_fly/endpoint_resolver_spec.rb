module ConcourseFly
  RSpec.describe EndpointResolver do
    subject { EndpointResolver.new "v5.8.0" }
    context "#fetch" do
      before :each do
        stub_request(:get, /github/)
          .to_return(body: '{Path: "/api/v1/info", Method: "GET", Name: "GetInfo"},')
      end
      context "when cached file is available" do
        before :each do
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:read).and_return(<<~YAML)
            ---
            foo: bar
          YAML
        end
        it "returns the value from cached file" do
          expect(subject.fetch).to eq({"foo" => "bar"})
        end
      end
      context "when cached file is unavailable" do
        before :each do
          allow(File).to receive(:exist?).and_return(false)
        end
        it "retrieves from Concourse repository" do
          expect(subject.fetch).to eq({"GetInfo" => {"path" => "/api/v1/info", "method" => "GET"}})
        end
      end
      context "when ignore_cache is true" do
        before :each do
          allow(File).to receive(:exist?).and_return(true)
        end
        it "does not read from cached file" do
          expect(File).not_to receive(:read)
        end
        it "retrieves from Concourse repository" do
          expect(subject.fetch(false)).to eq({"GetInfo" => {"path" => "/api/v1/info", "method" => "GET"}})
        end
      end
    end
  end
end
