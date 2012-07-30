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
  }
)
