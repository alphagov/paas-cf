require_relative "../backtick_cop"

RSpec.describe RuboCop::Cop::CustomCops::MustCaptureXStr do
  subject(:cop) { described_class.new }

  context "when there are no backticks" do
    it "detects no offenses" do
      inspect_source <<~RUBY
        puts "hello"
      RUBY

      expect(cop.offenses).to be_empty
    end
  end

  context "when there is a backtick execution string" do
    context "and it is not captured into a local variable" do
      it "detects an offense" do
        inspect_source <<~RUBY
          `echo hello world`
        RUBY

        expect(cop.offenses.first.message).to eq(
          "Must capture execution string output",
        )
      end
    end

    context "and it is assigned to a local variable" do
      it "detects no offenses" do
        inspect_source <<~RUBY
          my_var = `echo hello world`
        RUBY

        expect(cop.offenses).to be_empty
      end
    end
  end

  context "when there is a %x execution string" do
    context "and it is not captured into a local variable" do
      it "detects an offense" do
        inspect_source <<~RUBY
          %x(echo hello world)
        RUBY

        expect(cop.offenses.first.message).to eq(
          "Must capture execution string output",
        )
      end
    end

    context "and it is assigned to a local variable" do
      it "detects no offenses" do
        inspect_source <<~RUBY
          my_var = %x(echo hello world)
        RUBY

        expect(cop.offenses).to be_empty
      end
    end
  end
end

RSpec.describe RuboCop::Cop::CustomCops::MustCheckXStrExitstatus do
  subject(:cop) { described_class.new }

  context "when there are no backticks" do
    it "detects no offenses" do
      inspect_source <<~RUBY
        puts "hello"
      RUBY

      expect(cop.offenses).to be_empty
    end
  end

  context "when there is a backtick execution string" do
    context "and neither $? nor $CHILD_STATUS is checked" do
      it "detects an offense" do
        inspect_source <<~RUBY
          `echo hello world`
        RUBY

        expect(cop.offenses.first.message).to eq(
          "After using execution string must check exitstatus",
        )
      end
    end

    context "and $? is checked" do
      it "detects no offenses" do
        inspect_source <<~RUBY
          `echo hello world`
          abort 'error' unless $?.success?
        RUBY

        expect(cop.offenses).to be_empty
      end
    end

    context "and $CHILD_STATUS is checked" do
      it "detects no offenses" do
        inspect_source <<~RUBY
          `echo hello world`
          abort 'error' unless $CHILD_STATUS.success?
        RUBY

        expect(cop.offenses).to be_empty
      end
    end
  end

  context "when there is a %x execution string" do
    context "and neither $? nor $CHILD_STATUS is checked" do
      it "detects an offense" do
        inspect_source <<~RUBY
          %x(echo hello world)
        RUBY

        expect(cop.offenses.first.message).to eq(
          "After using execution string must check exitstatus",
        )
      end
    end

    context "and $? is checked" do
      it "detects no offenses" do
        inspect_source <<~RUBY
          `echo hello world`
          abort 'error' unless $?.success?
        RUBY

        expect(cop.offenses).to be_empty
      end
    end

    context "and $CHILD_STATUS is checked" do
      it "detects no offenses" do
        inspect_source <<~RUBY
          `echo hello world`
          abort 'error' unless $CHILD_STATUS.success?
        RUBY

        expect(cop.offenses).to be_empty
      end
    end
  end

  context "when there are multiple execution strings" do
    context "and none of them are checked" do
      it "detects many offenses" do
        inspect_source <<~RUBY
          `echo hello world`
          `echo hello again`
          `echo goodbye`
        RUBY

        expect(cop.offenses.length).to eq(3)
      end
    end

    context "and the first one is checked" do
      it "detects offenses for the remaining execution strings" do
        inspect_source <<~RUBY
          `echo hello world`
          abort 'error' unless $CHILD_STATUS.success?
          `echo hello again`
          `echo goodbye`
        RUBY

        expect(cop.offenses.length).to eq(2)
        expect(cop.offenses.map { |o| o.location.line }).to eq([3, 4])
      end
    end

    context "and the second one is checked" do
      it "detects offenses for the remaining execution strings" do
        inspect_source <<~RUBY
          `echo hello world`
          `echo hello again`
          abort 'error' unless $CHILD_STATUS.success?
          `echo goodbye`
        RUBY

        expect(cop.offenses.length).to eq(2)
        expect(cop.offenses.map { |o| o.location.line }).to eq([1, 4])
      end
    end

    context "and the last one is checked" do
      it "detects offenses for the remaining execution strings" do
        inspect_source <<~RUBY
          `echo hello world`
          `echo hello again`
          `echo goodbye`
          abort 'error' unless $CHILD_STATUS.success?
        RUBY

        expect(cop.offenses.length).to eq(2)
        expect(cop.offenses.map { |o| o.location.line }).to eq([1, 2])
      end
    end
  end
end
