RSpec.describe "fnv" do
  # see alphagov/paas-admin for identical tests
  [
    %w[guid-1 ux4xkdjccy5em],
    %w[guid-2 ux4xidjccy4jg],
    %w[guid-3 ux4xgdjccy3oa],
    %w[guid-4 ux4xudjcczbmk],
    %w[guid-5 ux4xsdjcczare],
    %w[guid-6 ux4xqdjccy7v6],
    %w[guid-7 ux4xodjccy62y],
    %w[guid-8 ux4x4djcczezc],
    %w[guid-9 ux4x2djcczd54],
    %w[guid-10 duofwuhlyvlie],
    %w[guid-11 duofyuhlyvmdk],
    %w[guid-12 duofsuhlyvjry],
    %w[guid-13 duofuuhlyvkm6],
    %w[guid-14 duofouhlyvh3m],
    %w[guid-15 duofquhlyviws],
  ].each do |input, expected_output|
    it "produces the base32 encoded fnv hash for '#{input}'" do
      expect(fnv(input)).to eq(expected_output)
    end
  end
end
