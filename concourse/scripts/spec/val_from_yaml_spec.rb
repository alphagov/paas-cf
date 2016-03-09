require File.join(File.dirname(__FILE__), '..', 'val_from_yaml.rb')

RSpec.describe "PropertyTreeHelper" do
  let(:test_property_tree) {
    property_yaml = %q{
---
foo:
 bar:
  val1: a
  val2: b
 array1:
 - name: item1
   val: array1_item1_value
 - name: item2
   val: array1_item2_value
 array2:
 - array2_value1
 - array2_value2
 - array2_value3
}
    PropertyTree.load_yaml(property_yaml)
  }
  it "retrieves a simple value" do
    expect(test_property_tree['foo.bar.val1']).to eq('a')
  end
  it "retrieves a full data structure" do
    val = test_property_tree['foo.bar']
    expect(val).to be_a(Hash)
    expect(val).to include('val1', 'val2')
  end
  it "returns nil for non existing properties" do
    expect(test_property_tree['x.y.z']).to be_nil
  end
  it "returns nil when trasversing simple values" do
    expect(test_property_tree['foo.var.val1.nothing_to_see_here']).to be_nil
  end
  it "retrieves a value from an array indexed by name" do
    expect(test_property_tree['foo.array1.item1.val']).to eq('array1_item1_value')
  end
  it "returns nil for non existing array item indexed by name" do
    expect(test_property_tree['foo.array1.item3.val']).to be_nil
  end
  it "returns nil for non existing key in a array item indexed by name" do
    expect(test_property_tree['foo.array1.item1.other_val']).to be_nil
  end
  it "retrieves a value from an array indexed by index" do
    expect(test_property_tree['foo.array2.0']).to eq('array2_value1')
  end
  it "retrieves a value from an array of hashes indexed by index" do
    expect(test_property_tree['foo.array1.0.val']).to eq('array1_item1_value')
  end
end
