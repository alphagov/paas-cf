require 'yaml'
require 'uri'

USERS_CONFIG_FILE_PATH = File.expand_path(File.join(__dir__, '..', 'users.yml'))

describe 'users config' do
  let :users_file_contents do
    File.read(USERS_CONFIG_FILE_PATH)
  end

  let :users do
    YAML.safe_load(users_file_contents)
  end

  let :users_grouped_by_permissions do
    users.group_by { |user| user['cf_admin'] }
  end

  it 'should be valid YAML' do
    expect { users }.not_to raise_exception, 'users config is invalid yaml'
  end

  it 'should provide a valid email for each user' do
    users.each do |user|
      expect(user['email']).to match URI::MailTo::EMAIL_REGEXP
    end
  end

  it 'should not have any unexpected fields' do
    fields = users.map(&:keys).flatten.uniq.sort
    expect(fields).to eq %w[cf_admin email google_id]
  end

  it 'should list users with the same permissions in alphabetical order' do
    users_grouped_by_permissions.each do |_, user_group|
      user_group.each_cons(2) do |user, following_user|
        emails = [user['email'], following_user['email']]
        expect(emails.sort).to eq emails
      end
    end
  end
end
