require "spec_helper"
require "serverspec"

user    = "hass"
group   = user
service = case os[:family]
          when "freebsd"
            "hass"
          end
ports   = [80, 8123]
home = "/usr/home/#{user}"
venv_dir = home
venv_bin_dir = "#{venv_dir}/bin"
config_dir = "#{home}/.homeassistant"
config = "#{config_dir}/configuration.yaml"

describe group group do
  it { should exist }
end

describe user user do
  it { should exist }
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
end

describe file "#{config_dir}/secrets.yaml" do
  it { should exist }
  it { should be_file }
  it { should be_mode 640 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
end

describe file "#{config_dir}/foo" do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file "#{config_dir}/foo/bar.yaml" do
  it { should exist }
  it { should be_file }
  it { should be_mode 640 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
end

describe file venv_bin_dir do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe command "cd #{venv_dir} && . bin/activate; pip3 list" do
  its(:exit_status) { should eq 0 }
  # XXX pip warns:
  # WARNING: You are using pip version ...
  #
  # its(:stderr) { should eq "" }
  its(:stdout) { should match(/^homeassistant\s+/) }
end

describe service service do
  it { should be_enabled }
  it { should be_running }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command "curl -v http://127.0.0.1" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should match(Regexp.escape("HTTP/1.1 302 Found")) }
  its(:stderr) { should match(Regexp.escape("location: /onboarding.html")) }
end

describe command "curl -v http://127.0.0.1/onboarding.html" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should match(Regexp.escape("HTTP/1.1 200 OK")) }
  its(:stdout) { should match(Regexp.escape("<title>Home Assistant</title>")) }
end
