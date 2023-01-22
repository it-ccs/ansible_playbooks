#!/usr/local/bin/zsh

shareDefaultMultiProtocol="MULTI_PROTOCOL_AFP"

if [[ -n "`echo "$1" | egrep '([\\-]+(h|help))'`" ]]; then
  cat<<EOF
$0 expects the following enironment variables:
  shareName               Name of the SMB share to create.
  sharePath               Path for the share.
  shareMultiProtocol      *Optional* Whether to adjust Samba settings to play nice
                            with another sharing protocol (default = MULTI_PROTOCOL_AFP):
                            NO_PRESET, DEFAULT_SHARE,ENHANCED_TIMEMACHINE, MULTI_PROTOCOL_AFP,
                             MULTI_PROTOCOL_NFS, PRIVATE_DATASETS, WORM_DROPBOXH
EOF
fi

if [[ -z "$shareName" ]]; then
  echo "Missing shareName environment variable." >&2
  exit 1
fi
if [[ -z "$sharePath" ]]; then
  echo "Missing sharePath environment variable." >&2
  exit 1
fi
multiProtocolRegex="(NO_PRESET|DEFAULT_SHARE|ENHANCED_TIMEMACHINE|MULTI_PROTOCOL_AFP|MULTI_PROTOCOL_NFS|PRIVATE_DATASETS|WORM_DROPBOXH)"
if [[ -z "$shareMultiProtocol" ]]; then
  shareMultiProtocol="$shareDefaultMultiProtocol"
elif [[ -z "`echo "$shareMultiProtocol" | egrep "^$multiProtocolRegex$"`" ]]; then
  echo "'$shareMultiProtocol' is not a valid option for shareMultiProtocol. Please use one of the following: `echo "$multiProtocolRegex"|sed 's/[\(\)]//;s/|/, /'`" >&2
  exit 1
fi

smbShareCheckResult=$(midclt call sharing.smb.query "[[\"name\",\"=\",\"$shareName\"]]")
if [[ -z "$(echo "$smbShareCreateResult" | jq -r -M "select(.name == \"$shareName\")")" ]]; then
  smbShareCreateResult=$(midclt call sharing.smb.create "{\"purpose\": \"$shareMultiProtocol\", \"path\": \"$sharePath\", \"path_suffix\": \"\", \"home\": false, \"name\": \"$shareName\", \"comment\": \"\", \"ro\": false, \"browsable\": true, \"recyclebin\": false, \"guestok\": false, \"hostsallow\": [], \"hostsdeny\": [], \"auxsmbconf\": \"\", \"aapl_name_mangling\": true, \"abe\": true, \"acl\": true, \"durablehandle\": false, \"streams\": true, \"timemachine\": false, \"shadowcopy\": true, \"fsrvp\": false, \"enabled\": true}" 2>&1)
  if [[ -z "$(echo "$smbShareCreateResult" | jq "select(.name == \"$shareName\")")" ]]; then
    echo "Error creating '$shareName': $smbShareCreateResult"
    exit 1
  fi
  echo "Created the smb share '$shareName'."
else
  echo "Samba share '$shareName' already exists."
fi
