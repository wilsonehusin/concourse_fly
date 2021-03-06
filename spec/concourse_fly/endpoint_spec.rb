module ConcourseFly
  RSpec.describe Endpoint do
    subject { Endpoint.new "foo", "GET", "/foo/:country" }
    it "converts to dictionary nicely" do
      expect(subject.to_h).to eq({name: "foo", http_method: "GET", path: "/foo/:country"})
    end
    context "#interpolate" do
      it "interpolates :variables with provided values" do
        vars = {country: "indonesia"}
        expect(subject.interpolate(vars)).to eq "/foo/indonesia"
      end
    end
  end
  RSpec.describe EndpointImporter do
    subject { EndpointImporter.new "v5.8.0" }
    describe "#fetch" do
      before :each do
        stub_request(:get, /github/)
          .to_return(body: '{Path: "/api/v1/info", Method: "GET", Name: "GetInfo"},')
      end
      context "when cached file is available" do
        before :each do
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:read).and_return(<<~YAML)
            ---
            - name: ListActiveUsersSince
              http_method: GET
              path: "/api/v1/users"
          YAML
        end
        it "returns the value from cached file" do
          expect(subject.fetch).to eq([Endpoint.new("ListActiveUsersSince", "GET", "/api/v1/users")])
        end
      end
      context "when cached file is unavailable" do
        before(:each) { allow(File).to receive(:exist?).and_return(false) }
        it "retrieves from Concourse repository" do
          expect(subject.fetch).to eq([Endpoint.new("GetInfo", "GET", "/api/v1/info")])
        end
      end
      context "when ignore_cache is true" do
        before(:each) { allow(File).to receive(:exist?).and_return(true) }
        it "does not read from cached file" do
          expect(File).not_to receive(:read)
        end
        it "retrieves from Concourse repository" do
          expect(subject.fetch(false)).to eq([Endpoint.new("GetInfo", "GET", "/api/v1/info")])
        end
      end
    end
  end
end
