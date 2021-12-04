require "spec_helper"
require "serverspec"

package = "homeassistant"
user    = "hass"
group   = user
ports   = [8123]
home = "/usr/home/#{user}"
config = "#{home}/.homeassistant/configuration.yaml"
venv_dir = "#{home}"
venv_bin_dir = "#{venv_dir}/bin"

describe file(config) do
  it { should exist }
  it { should be_file }
  # it { should be_mode  }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file venv_bin_dir do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
