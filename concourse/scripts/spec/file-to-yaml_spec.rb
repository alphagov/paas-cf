require 'yaml'

RSpec.describe "file-to-yaml.sh", :type => :aruba do

  context("given two keys and a text file") do

    before(:each) do
      @some_content = "Some content"
      @tmp_file_path = "#{@workdir}/ouput.txt"
      @tmp_file = File.new(@tmp_file_path, "w")
      @tmp_file.puts(@some_content)
      @tmp_file.close
    end

    it("should generate a simple YAML structure") do
      run("./file-to-yaml.sh key_one key_two #{@tmp_file_path}")
      expect(last_command_started).to have_exit_status(0)
      yaml_output = last_command_started.output
      yaml_data = YAML.load(yaml_output)
      expect(yaml_data.key?("key_one")).to be true
      expect(yaml_data["key_one"].key?("key_two")).to be true
      expect(yaml_data["key_one"]["key_two"]).to eq("#{@some_content}\n")
    end

  end

end
