module ConcourseFly
  RSpec.describe Client do
    let(:auth_header) { {"Authorization" => "Bearer fake_token"} }
    let(:concourse_url) { "https://wings.pivotal.io" }
    context "unauthenticated API" do
      subject { Client.new concourse_url }
      describe "#version" do
        before :each do
          stub_request(:get, "#{concourse_url}/api/v1/info")
            .to_return(status: 200, body: '{"version":"5.8.0","worker_version":"2.2","external_url":"https://wings.pivotal.io"}')
        end
        it "converts version to Git tag convetion" do
          expect(subject.version).to eq("v5.8.0")
        end
      end
      describe "#users" do
        before :each do
          stub_request(:get, "#{concourse_url}/api/v1/users")
            .to_return(status: 401, body: "something not json")
        end
        it "raises AuthError" do
          expect { subject.users }.to raise_error AuthError
        end
      end
    end
    context "authenticated API" do
      subject do
        Client.new(concourse_url) do |c|
          c.auth_type = :flyrc
          c.flyrc_target = "some-target"
        end
      end
      before :each do
        allow(File).to receive(:read).and_return(<<~YAML)
          - name: ListBuilds
            method: GET
            path: "/api/v1/builds"
          - name: ListActiveUsersSince
            method: GET
            path: "/api/v1/users"
        YAML
        allow(File).to receive(:read).with(/flyrc/).and_return(<<~YAML)
          targets:
            some-target:
              api: https://wings.pivotal.io
              team: main
              token:
                type: Bearer
                value: fake_token
        YAML
      end
      describe "#users" do
        before :each do
          stub_request(:get, "#{concourse_url}/api/v1/users")
            .with(headers: auth_header)
            .to_return(status: 200, body: '[{"id": 123, "username": "fake_user"}]')
        end
        it "returns list of users" do
          expect(subject.users).to eq([{"id" => 123, "username" => "fake_user"}])
        end
      end
      describe "#[]" do
        before :each do
          stub_request(:get, "#{concourse_url}/api/v1/builds")
            .with(headers: auth_header)
            .to_return(status: 200, body: '[{"id": 1, "name": "main", "auth": {}}]')
        end
        it "makes a call given a valid endpoint (e.g. :list_builds)" do
          expect(subject[:list_builds]).to eq([{"id" => 1, "name" => "main", "auth" => {}}])
        end
      end
    end
  end
end
