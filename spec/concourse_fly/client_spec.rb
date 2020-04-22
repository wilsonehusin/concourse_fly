module ConcourseFly
  RSpec.describe Client do
    context "unauthenticated API" do
      subject { Client.new "https://wings.pivotal.io" }
      context "#validate_target!" do
        context "when target matches" do
          it "returns true" do
            stub = stub_request(:get, "https://wings.pivotal.io/api/v1/info")
              .to_return(body: '{"external_url": "https://wings.pivotal.io"}')
            expect(subject.validate_target!).to eq true
            expect(stub).to have_been_requested
          end
        end
        context "when target does not match" do
          it "raises TargetError" do
            stub_request(:get, "https://wings.pivotal.io/api/v1/info")
              .to_return(body: '{"external_url": "https://wingo.pivotal.io"}')
            expect { subject.validate_target! }.to raise_error TargetError
          end
        end
        context "when response is not understandable" do
          it "raises ResponseError" do
            stub_request(:get, "https://wings.pivotal.io/api/v1/info")
              .to_return(body: "something not json")
            expect { subject.validate_target! }.to raise_error ResponseError
          end
        end
        context "when Faraday raises arbitrary error" do
          it "raises FlyError" do
            stub_request(:get, "https://wings.pivotal.io/api/v1/info")
              .to_raise(Faraday::Error, nil)
            expect { subject.validate_target! }.to raise_error FlyError
          end
        end
      end
      context "#users" do
        it "raises AuthError" do
          stub_request(:get, "https://wings.pivotal.io/api/v1/users")
            .to_return(status: 401, body: "something not json")
          expect { subject.users }.to raise_error AuthError
        end
      end
    end
    context "authenticated API" do
      subject do
        Client.new("https://wings.pivotal.io") do |c|
          c.auth_type = :flyrc
          c.flyrc_target = "some-target"
        end
      end
      context "#users" do
        it "returns list of users" do
          stub_request(:get, "https://wings.pivotal.io/api/v1/users")
            .to_return(status: 401, body: "something not json")
          stub_request(:get, "https://wings.pivotal.io/api/v1/users")
            .with(headers: {"Authorization" => "Bearer fake_token"})
            .to_return(status: 200, body: '[{"id": 123, "username": "fake_user"}]')
          allow(File).to receive(:read).and_return nil
          fake_flyrc = <<~YAML
            targets:
              some-target:
                api: https://wings.pivotal.io
                team: main
                token:
                  type: Bearer
                  value: fake_token
          YAML
          allow(File).to receive(:read).with("~/.flyrc").and_return(fake_flyrc)

          expect(subject.users).to eq([{"id" => 123, "username" => "fake_user"}])
        end
      end
    end
  end
end
