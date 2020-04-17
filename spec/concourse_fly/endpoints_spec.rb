module ConcourseFly
  RSpec.describe Endpoints do
    it "initializes appropriately" do
      expect { Endpoints.new }.not_to raise_error
    end
  end
end
