require_relative "../../scripts/reorder-yaml.rb"

RSpec.describe "reorder-yaml" do
  let(:torture_test_input) do
    YAML.safe_load <<~FIXTURE
      foo:
      - bar: baz
        abc: [1,2,3]
      - name: foo
        __paas_order: -1
        bar:
          __paas_order: 2
          abc:
          - __paas_order: 3
          - __paas_order: -1
            foo: 12.34
            bar: false
          - __paas_order: 2
            qux: zap
          - qux: abc
          -
            - name: abc
              __paas_order: xyz
            - name: xyz
              __paas_order: abc
          fred:
            __paas_order: abc
      - bar: qux
        __paas_order: 9
      - bar: blah
        __paas_order: 2.01
      - blah: bar
        __paas_order: 2
      - 3.1415
      - __paas_order  # i.e. a literal string
      zap: 321
    FIXTURE
  end

  let(:torture_test_expected_output) do
    YAML.safe_load <<~FIXTURE
      foo:
      - name: foo
        bar:
          abc:
          - foo: 12.34
            bar: false
          - qux: abc
          -
            - name: xyz
            - name: abc
          - qux: zap
          - {}  # only key was __paas_order
          fred: {}  # only key was __paas_order
      - bar: baz
        abc: [1,2,3]
      - 3.1415
      - __paas_order  # literal string still present
      - blah: bar
      - bar: blah
      - bar: qux
      zap: 321
    FIXTURE
  end

  describe "torture test" do
    it "returns the correct output" do
      actual_output = processed(torture_test_input)
      expect(actual_output).to eq(torture_test_expected_output)
    end
  end
end
