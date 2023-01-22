#!/usr/local/bin/zsh

if [[ -n "`echo "$1" | egrep '([\\-]+(h|help))'`" ]]; then
  cat<<EOF
$0 expects the following enironment variables:
  zDataset      ZFS dataset to create in format <zpool_name>/<dataset_name>
EOF
fi

if [[ -z "$zDataset" ]]; then
  echo "Missing zDataset environment variable." >&2
  exit 1
fi

zsetCheckResult=`midclt call pool.dataset.query "[[\"id\",\"=\",\"$zDataset\"]]"`
if [[ "$zsetCheckResult" != "[]" ]]; then
  echo "Dataset '$zDataset' already exists."
  exit
fi

## if the dataset doesn't already exist, create it
zsetCreateResult=`midclt call pool.dataset.create "{\"type\":\"FILESYSTEM\", \"compression\":\"LZ4\", \"aclmode\":\"PASSTHROUGH\", \"name\":\"$zDataset\"}" 2>&1`
if [[ -z "`echo "$zsetCreateResult" | jq "select(.id == \\"$zDataset\\")"`" ]]; then
  echo "Error creating '$zDataset': $zsetCreateResult"
  exit 1
fi

# midclt call pool.dataset.query "[[\"id\",\"=\",\"$zDataset\"]]" | jq -Mr '.[]|.mountpoint'
echo "Created '$zDataset' dataset."