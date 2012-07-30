name "web"
description "The web app role"
run_list [
  "curbstreet::base",
  "curbstreet::web"
]

default_attributes(
  "authorization" => {
    "sudo" => {
      "users"         => ["root"],
      "groups"        => ["sudo", "admin", "sysadmin"],
      "passwordless"  => true
    }
  },
  "rvm" => {
    "user_installs" => {
      'user'          => 'deployer',
      'default_ruby'  => 'ruby-1.9.3p194',
      'rubies'        => ['1.9.3p194']
    }
  }
)
