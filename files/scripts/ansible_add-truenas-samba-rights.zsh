#!/usr/local/bin/zsh

authFilePath="/tmp/samba.`echo "$RANDOM"`.cred"

cleanup() {
  typeset -a filesToDelete
  filesToDelete=( $authFilePath )
  
  for f in ${filesToDelete[@]}; do
	  test -f $f && rm -Rf $f
  done
}

## If Ctrl+C is hit during script execution and a sensitive file has been created, trap the Ctrl+C
#   and run the function to ensure the files are deleted and do no remain.
#   The numbers are integers that represent different signals to catch in addition to Ctrl+C
trap "{cleanup; exit 1}" 1 2 3 4 15

if [[ -n "`echo "$1" | egrep '([\\-]+(h|help))'`" ]]; then
  cat<<EOF
$0 expects the following enironment variables:
  adAdminUser       User with privileges to grant rights.
  adAdminPwd        Password of user with privileges to grant rights.
  adNetBIOSDomain   The ActiveDirectory NetBIOS domain name.
  addUser           User to grant rights to.
  rights            Comma separated list of rights to grant user.
EOF
fi

if [[ -z "$adAdminUser" ]]; then
  echo "Missing adAdminUser environment variable." >&2
  exit 1
fi
if [[ -z "$adAdminPwd" ]]; then
  echo "Missing adAdminPwd environment variable." >&2
  exit 1
fi
if [[ -z "$adNetBIOSDomain" ]]; then
  echo "Missing adNetBIOSDomain environment variable." >&2
  exit 1
fi
if [[ -z "$addUser" ]]; then
  echo "Missing addUser environment variable." >&2
  exit 1
fi
if [[ -z "$rights" ]]; then
  echo "Missing rights environment variable." >&2
  exit 1
fi

