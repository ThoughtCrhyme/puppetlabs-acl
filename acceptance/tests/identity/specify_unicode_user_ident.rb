test_name 'Windows ACL Module - Specify User Name Containing Unicode for Identity'

confine(:to, :platform => 'windows')

#Globals
target_parent = 'c:/temp'
prefix = SecureRandom.uuid.to_s
target = "c:/temp/#{prefix}.txt"
raw_user_id = 'user_\uB81D\uB534\uC2AB\uC788\uCC98'
user_id =     "user_\uB81D\uB534\uC2AB\uC788\uCC98" # 렝딴슫있처

file_content = 'Flying Spaghetti Monster wants to save your soul.'
verify_acl_command = "(Get-ACL '#{target}' | ForEach-Object { $_.Access } | Where-Object { $_.IdentityReference -match ('\\\\' + [regex]::Unescape(\"#{raw_user_id}\")) -and $_.FileSystemRights -eq 'FullControl' } | Measure-Object).Count"

#Manifest
acl_manifest = <<-MANIFEST
file { '#{target_parent}':
  ensure => directory
}

file { '#{target}':
  ensure  => file,
  content => '#{file_content}',
  require => File['#{target_parent}']
}

user { '#{user_id}':
  ensure     => present,
  groups     => 'Users',
  managehome => true,
  password   => "L0v3Pupp3t!"
}

acl { '#{target}':
  permissions  => [
    { identity => '#{user_id}', rights => ['full'] },
  ],
}
MANIFEST

#Tests
agents.each do |agent|
  step "Execute Manifest"
  apply_manifest_on(agent, acl_manifest, {:debug => true}) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step "Verify that ACL Rights are Correct"
  on(agent, powershell(verify_acl_command, {'EncodedCommand' => true})) do |result|
    assert_match(/^1$/, result.stdout, 'Expected ACL was not present!')
  end
end
