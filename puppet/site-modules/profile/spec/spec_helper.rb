require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.default_facts = {
    'os' => {
      'family'       => 'Darwin',
      'name'         => 'Darwin',
      'architecture' => 'arm64',
      'release'      => {
        'major' => '24',
        'full'  => '24.0.0',
      },
      'macosx' => {
        'version' => {
          'major' => '15',
          'full'  => '15.0',
        },
      },
    },
    'kernel'          => 'Darwin',
    'kernelrelease'   => '24.0.0',
    'osfamily'        => 'Darwin',
    'operatingsystem' => 'Darwin',
    'architecture'    => 'arm64',
    'id'              => 'ec2-user',
    'path'            => '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

  c.hiera_config = File.join(__dir__, 'fixtures', 'hiera.yaml')

  c.module_path = [
    File.join(__dir__, '..', '..', '..', 'site-modules'),
    File.join(__dir__, 'fixtures', 'modules'),
  ].join(':')
end
