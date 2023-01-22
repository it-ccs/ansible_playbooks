#!/usr/local/bin/zsh

defaultAclReplacePermission="FALSE"
defaultAclRecurse="FALSE"

if [[ -n "`echo "$1" | egrep '([\\-]+(h|help))'`" ]]; then
  cat<<EOF
Prepends an
  $0 expects the following enironment variables:
  ace                     NFSv4 format access control entry
                            <type>:<principal>:<permission(s)>:<flags>
                            group:Administrators:
  aclPath                 Path to the file/directory on which to change permissions.
  replaceAclPermission    If this is TRUE, any existing permissions of the
                            principal will be replaced with provided permissions.
                            Default is $defaultReplacePermission.
  aclRecurse              If this is TRUE and aclPath is a directory, the ace will be
                            recursively applied to subdirectories and files. Default is
                            $defaultRecurse.
EOF
fi

typeset -a setfaclArgs

if [[ -z "$aclRecurse" ]]; then
  aclRecurse="$defaultAclRecurse"
else
  if [[ -z "`echo "$aclRecurse" | egrep -i '^(true|false)$'`" ]]; then
    echo "invalid value '$aclRecurse' for aclRecurse. Must be TRUE or FALSE."
  fi
fi

[[ "$aclRecuse" == "TRUE" ]] && setfaclArgs=( "-R" "-m" ) || setfaclArgs=( "-m" )

if [[ -z "$ace" ]]; then
  echo "Missing ace environment variable." >&2
  exit 1
fi

setfaclArgs=( $setfaclArgs "$ace" )

if [[ -z "$aclPath" ]]; then
  echo "Missing aclPath environment variable." >&2
  exit 1
else
  test -d "$aclPath" && isdir="TRUE" || isdir="FALSE"
  test -f "$aclPath" && isfile="TRUE" || isfile="FALSE"
  if [[ "$isdir"=="FALSE" && "$isfile"=="FALSE" ]]; then
    echo "Path '$aclPath' does not exist."
    exit 1
  fi
fi

setfaclArgs=( $setfaclArgs "$aclPath" )

if [[ -z "$replaceAclPermission" ]]; then
  replacePermission="$defaultReplaceAclPermission"
else
  if [[ -z "`echo "$replaceAclPermission" | egrep -i '^(true|false)$'`" ]]; then
    echo "'$replaceAclPermission' is not valid for replacePermission. Must be TRUE or FALSE."
  fi
fi

## get current ACL to compare later
currentAcl=`getfacl "$aclPath" | awk 'NR > 3 && $1!~/^#/'`

## set ace
setfactlOutput=`setfacl $setfaclArgs`
setfaclExitCode=$?

if [[ "$?" -gt 0 ]]; then

fi