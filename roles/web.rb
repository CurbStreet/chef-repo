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

  "curbstreet" => {
    "repository"  => "git@github.com:CurbStreet/curbstreet.rb.git",
    "revision"    => "HEAD",
    "environment" => {
      "RACK_ENV"  => "development"
    },
    "config_files_to_symlink" => {
        'config/elasticsearch.yml' => 'config/elasticsearch.yml',
        'config/session.yml' => 'config/session.yml',
        'config/mongoid.yml' => 'config/mongoid.yml'
    }
  }
)

override_attributes(
  "rvm"   => {
    "user_installs" => [{
      "user"          => "deployer",
      "default_ruby"  => "ruby-1.9.3-p194",
      "rubies"        => ["ruby-1.9.3-p194"],
      "global_gems"   => [{
        'name'  => 'bundler'
      },{
        'name'  => 'rake'
      }],
      'rvmrc'         => {
        'rvm_project_rvmrc'             => 1,
        'rvm_gemset_create_on_use_flag' => 1,
        'rvm_pretty_print_flag'         => 1
      }
    }]
  }
)