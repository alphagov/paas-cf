def each_kv_recursive(obj, &block)
  case obj
  when Hash
    obj.each do |k, v|
      block.call(k, v)
      each_kv_recursive(v, &block)
    end
  when Array
    obj.each do |v|
      each_kv_recursive(v, &block)
    end
  end
end

RSpec.shared_examples "an autoscaler rds client" do
  let(:jobs) { subject["jobs"] }

  it_behaves_like "a cf rds client"

  it "uses the rds database for all jobs" do
    jobs.each do |job|
      each_kv_recursive job do |k, v|
        next unless k.end_with?("_db") && v.is_a?(Hash)

        expect(v).to have_key("address")
        expect(v["address"]).to eq("abcd.postgres.aws"), "#{k} doesn't appear to be using RDS: db address is #{v['address']}"
      end
    end
  end
end
