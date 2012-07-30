name "web"
description "The web app role"
run_list [
  "curbstreet::base",
  "mongodb::default",
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
  },

  "nodejs" => {
    "versions"        => ["0.8.4"],
    "default"         => "0.8.4",
    "global_packages" => ["coffee-script", "stylus"]
  },

  "unicorn" => {
    "listen"            => "127.0.0.1:3000",
    "pid"               => "tmp/pids/unicorn.pid",
    "stderr_path"       => "log/unicorn_stderr.log",
    "stdout_path"       => "log/unicorn_stdout.log",
    "timeout"           => 3,
    "worker_processes"  => 2
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
        'rvm_project_rvmrc'             => 0,
        'rvm_gemset_create_on_use_flag' => 0,
        'rvm_pretty_print_flag'         => 0
      }
    }]
  }
)