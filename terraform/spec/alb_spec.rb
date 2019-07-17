describe 'alb' do
  terraform_files = TERRAFORM_FILES
    .reject { |f| File.read(f).lines.grep(/resource\s+"aws_lb"/).empty? }

  terraform_contents = terraform_files
    .map { |f| File.read(f) }
    .join("\n\n")

  terraform = HCL::Checker.parse(terraform_contents)

  it 'should not contain any aws_alb resources' do
    expect(
      TERRAFORM_FILES
        .map { |f| File.read(f) }.join("\n").lines .grep(/"aws_alb"/)
    ).to be_empty
  end

  it 'should be have terraform files describing albs' do
    expect(terraform_files).not_to be_empty
  end

  it 'should be valid terraform' do
    expect(terraform).not_to be(false)
  end

  it 'should have names less than 32 characters' do
    lb_names = terraform
      .dig('resource', 'aws_lb').values
      .map { |r| r.dig('name') }
      .map { |val| val.gsub('${var.env}', 'prod-lon') }


    expect(lb_names).to all(match(/^[-a-z]{4,32}$/))
    expect(lb_names).not_to include(match('var.env'))
  end

  it 'should have access_logs configured' do
    access_logs = terraform
      .dig('resource', 'aws_lb').values
      .map { |r| r.dig('access_logs') }

    expect(access_logs).not_to include(nil)
  end

  it 'should not have deletion protection enabled' do
    deletion_protection = terraform
      .dig('resource', 'aws_lb').values
      .map { |r| r.dig('enable_deletion_protection') }

    expect(deletion_protection).to all(be(nil))
  end
end
