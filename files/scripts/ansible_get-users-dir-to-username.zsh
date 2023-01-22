#!/usr/local/bin/zsh

## This script gets a list of directories in the directory specified in the environment variable usersPath.
#   Then, assuming each directory corresponds to a username, check to see if that user exists and it it does
#   returns a list of directory paths to user in JSON format. If the user doesn't exist then the default user
#   is returned.

usage() {
  cat<<EOF
$0 expects the following environment variables:
  userDirsPath        Path to the home or profiles directory
  domain              The ActiveDirectory domain of the users
  defaultUser         If no corresponding user exists for the directory then
                        return this user as the owning user.
EOF
}

if [[ -n "`echo "$1" | egrep '([\\-]+(h|help))'`" ]]; then
  usage
fi

if [[ -z "$userDirsPath" ]]; then
  echo "Missing userDirsPath environment variable." >&2
  usage
  exit 1
fi

if [[ -z "$domain" ]]; then
  echo "Missing domain environment variable." >&2
  usage
  exit 1
fi

if [[ -z "$defaultUser" ]]; then
  echo "Missing defaultUser environment variable." >&2
  usage
  exit 1
fi

count=0
while read -r userdir; do
  # windows will append a '.V#' to the profiles dir, so remove that to determine username
  username=`basename "$userdir" | sed -r 's/\.[Vv]{1}[0-9]+$//'`
  ## check username
  wbinfo "--user-info=$domain\\$username" > /dev/null 2>&1
  [[ "$?" == 0 ]] || username="$defaultUser"
  if [[ $count == 0 ]]; then
    jsonlist="    { \"path\": \"$userdir\", \"username\": \"$username\" }"
  else
    jsonlist=`cat<<EOF
$jsonlist,
    { "path": "$userdir", "username": "$username" }
EOF
`
  fi
  ((count++))
  unset username
done <<< `find $userDirsPath -maxdepth 1 -mindepth 1 -type d`
unset count
cat<<EOF
{
  "users_dir_list": [
$jsonlist
  ]
}
EOF