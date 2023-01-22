#!/usr/local/bin/zsh

if [[ -n "`echo "$1" | egrep '([\\-]+(h|help))'`" ]]; then
  cat<<EOF
$0 expects the following enironment variables:
  poolName        ZFS Pool Name
  poolType        ZFS Pool Type to create (RAIDZ1, MIRROR, STRIPE, ...)
  poolDisks       Comma separate list of disks to create the pool with
EOF
fi

if [[ -z "$poolName" ]]; then
  echo "Missing poolName environment variable." >&2
  exit 1
fi
if [[ -z "$poolType" ]]; then
  echo "Missing poolType environment variable." >&2
  exit 1
fi
if [[ -z "$poolDisks" ]]; then
  echo "Missing poolDisks environment variable." >&2
  exit 1
fi

# make sure pool type is all upper case
poolType=`echo "$poolType" | tr '[:lower:]' '[:upper:]'`

typeset -a diskList
diskList=( `echo "$poolDisks" | sed -r 's/[ \t,]*/ /'` )


poolExistsCheck=$(midclt call pool.query "[[\"name\",\"=\",\"$poolName\"]]")
if [[ "$poolExistsCheck" != "[]" ]]; then
  echo "Pool already exits ($poolName)."
  exit
fi

otherPools=`midclt call pool.query "[[\"name\",\"!=\",\"$poolName\"]]"`
disksInUse=""
for disk in "${diskList[@]}"; do
  if [[ -n "`echo "$otherPools" | egrep "$disk"`" ]]; then
    if [[ -n "$disksInUse" ]]; then
      disksInUse="$disksInUse, $disk"
    else
      disksInUse="$disk"
    fi
  fi
done
if [[ -n "$disksInUse" ]]; then
  echo "Disk(s) in use by other pool(s): $disksInUse" >&2
  exit 1
fi

## verify that disks aren't in use some other way
disksInUse=""
for disk in "${diskList[@]}"; do
  diskParts=`gpart list -a $disk 2>/dev/null | awk "\\\$2==\"Name:\" && \\\$3!~/$disk\$/ {print \\\$3}"`
  if [[ -n "$diskParts" ]]; then
    if [[ -n "$disksInUse" ]]; then
      disksInUse="$disksInUse, $disk"
    else
      disksInUse="$disk"
    fi
  fi
done

if [[ -n "$disksInUse" ]]; then
  echo "Disk(s) unavailable to add to a pool: $disksInUse" >&2
  exit 1
fi

## create json list syntax of poolDisks
diskListJson=""
for disk in "${diskList[@]}"; do
  if [[ -z "$diskListJson" ]]; then
    diskListJson="[\"$disk\""
  else
    diskListJson="$diskListJson,\"$disk\""
  fi
done
diskListJson="$diskListJson]"

## issue create pool command
echo "midclt call pool.create \"{\"name\":\"$poolName\",\"topology\":{ \"data\": [ {\"type\": \"$poolType\", \"disks\": $diskListJson} ] }}\""
poolCreateJobId=$(midclt call pool.create "{\"name\":\"$poolName\",\"topology\":{ \"data\": [ {\"type\": \"$poolType\", \"disks\": $diskListJson} ] }}")
## wait until job is done
while [[ -z "`midclt call core.get_jobs "[[\\"id\\",\\"=\\",$poolCreateJobId]]" | jq -rM '.[]|select(.progress.percent==100 or .state=="FAILED")'`" ]]; do
  sleep 1;
done

## job details
if [[ -n "`midclt call core.get_jobs "[[\\"id\\",\\"=\\",$poolCreateJobId]]" | jq -rM '.[]|select(.state=="FAILED")'`" ]]; then
  echo "Failed to create pool. Error = `midclt call core.get_jobs "[[\\"id\\",\\"=\\",$poolCreateJobId]]" | jq -rM '.[]|.error'`" >&2
  exit 1
else
  echo "Pool has been created."
fi
