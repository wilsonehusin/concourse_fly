module ConcourseFly
  RSpec.describe Client do
    let(:auth_header) { {"Authorization" => "Bearer fake_token"} }
    let(:concourse_url) { "https://wings.pivotal.io" }
    context "unauthenticated HTTP requests" do
      subject { Client.new concourse_url }
      describe "#version" do
        before :each do
          stub_request(:get, "#{concourse_url}/api/v1/info")
            .to_return(status: 200, body: '{"version":"5.8.0","worker_version":"2.2","external_url":"https://wings.pivotal.io"}')
        end
        it "converts version to Git tag convention" do
          expect(subject.version).to eq("v5.8.0")
        end
      end
      describe "#[]" do
        before :each do
          stub_request(:get, "#{concourse_url}/api/v1/users")
            .to_return(status: 401, body: "something not json")
        end
        it "raises AuthError on :list_active_users_since" do
          expect { subject[:list_active_users_since] }.to raise_error AuthError
        end
      end
    end
    context "authorization" do
      before :each do
        allow(File).to receive(:read).and_return(<<~YAML)
          - name: GetInfoCreds
            http_method: GET
            path: "/api/v1/info/creds"
        YAML
        stub_request(:get, "#{concourse_url}/api/v1/info/creds")
          .with(headers: auth_header)
          .to_return(status: 200, body: "{}")
      end
      context "providing raw header" do
        subject do
          Client.new(concourse_url) do |c|
            c.auth_type = :raw
            c.auth_data = {raw: auth_header["Authorization"]}
          end
        end
        it "performs request with provided authorization header" do
          expect(subject[:get_info_creds]).to eq({})
        end
      end
      context "reading from ~/.flyrc" do
        subject do
          Client.new(concourse_url) do |c|
            c.auth_type = :flyrc
            c.auth_data = {flyrc_target: "some-target"}
          end
        end
        before :each do
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
        it "performs request with provided authorization header" do
          expect(subject[:get_info_creds]).to eq({})
        end
      end
      xcontext "local username:password" do
        subject do
          Client.new(concourse_url) do |c|
            c.auth_type = :local
            c.auth_data = {username: "airport", password: "CGK"}
          end
        end
        it "performs request with provided authorization header" do
          expect(subject[:get_info_creds]).to eq({})
        end
      end
    end
    context "authenticated HTTP requests" do
      subject do
        Client.new(concourse_url) do |c|
          c.auth_type = :raw
          c.auth_data = {raw: auth_header["Authorization"]}
        end
      end
      before :each do
        allow(File).to receive(:read).and_return(<<~YAML)
          - name: ListBuilds
            http_method: GET
            path: "/api/v1/builds"
          - name: ListActiveUsersSince
            http_method: GET
            path: "/api/v1/users"
          - name: RenamePipeline
            http_method: PUT
            path: "/api/v1/teams/:team_name/pipelines/:pipeline_name/rename"
        YAML
      end
      describe "#[]" do
        context "when no block is given" do
          before :each do
            stub_request(:get, "#{concourse_url}/api/v1/builds")
              .with(headers: auth_header)
              .to_return(status: 200, body: '[{"id": 1, "name": "main", "auth": {}}]')
          end
          context "when given a valid endpoint (e.g. :list_builds)" do
            it "automagically resolves to the request" do
              expect(subject[:list_builds]).to eq([{"id" => 1, "name" => "main", "auth" => {}}])
            end
          end
          context "when given an invalid endpoint (e.g. :fake_item)" do
            it "raises EndpointError" do
              expect { subject[:fake_item] }.to raise_error(EndpointError)
            end
          end
        end
        context "when given configurations in a block" do
          before :each do
            stub_request(:put, "#{concourse_url}/api/v1/teams/all-star/pipelines/old-pipeline/rename")
              .with(headers: auth_header, body: '{"name": "new-pipeline"}')
              .to_return(status: 204)
          end
          it "fills the path appropriately" do
            # The decision to explicitly include team_name is deliberate, since Concourse accepts
            # anyone authenticated in `main` team to modify other team's pipeline
            expect(
              subject[:rename_pipeline] { |options|
                options.path_vars = {team_name: "all-star", pipeline_name: "old-pipeline"}
                options.body = '{"name": "new-pipeline"}'
              }
            ).to eq true
          end
        end
      end
    end
  end
end
