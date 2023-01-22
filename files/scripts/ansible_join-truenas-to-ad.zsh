#!/usr/local/bin/zsh

adDefaultOU="Computers"
leaveDomainDefault="FALSE"

if [[ -n "`echo "$1" | egrep '([\\-]+(h|help))'`" ]]; then
  cat<<EOF
$0 expects the following enironment variables:
  adJoinUser          User with privileges to join a computer to ActiveDirectory.
  adJoinPwd           Password of user in adJoinUser with required privileges.
  adNetBIOSDomain     The ActiveDirectory NetBIOS domain.
  adDNSDomain         The ActiveDirectory DNS domain to join.
  adServerOU          *Optional* The ActiveDirectory organizational unit to create the server's
                        computer account in. This is in the format OU-1/OU-2 .
  leaveCurrentDomain  *Optional* If truenas is joined to a different domain and this is TRUE then
                        this script will leave the current domain and join the domain specified in
                        adDNSDomain. If FALSE then will will not leave current domain and will
                        throw an error instead. The default is FALSE .
EOF
fi

if [[ -z "$adJoinUser" ]]; then
  echo "Missing adJoinUser environment variable." >&2
  exit 1
fi
if [[ -z "$adJoinPwd" ]]; then
  echo "Missing adJoinPwd environment variable." >&2
  exit 1
fi
if [[ -z "$adNetBIOSDomain" ]]; then
  echo "Missing adNetBIOSDomain environment variable." >&2
  exit 1
fi
if [[ -z "$adDNSDomain" ]]; then
  echo "Missing adDNSDomain environment variable." >&2
  exit 1
fi
if [[ -z "$adServerOU" ]]; then
  adServerOU="$adDefaultOU"
fi
if [[ -z "$leaveCurrentDomain" ]]; then
  leaveCurrentDomain="$leaveDomainDefault"
fi

## determine whether joined to a domain or not
[[ "`midclt call activedirectory.get_state`" != "DISABLED" ]] && isJoined="TRUE" || isJoined="FALSE"
## check if joined to intended domain if already joined to AD
[[ "`wbinfo -D "$adDNSDomain" 2>/dev/null | awk '/Alt_Name/ {print toupper($3)}'`" == "`echo "$adDNSDomain" | tr '[:lower:]' '[:upper:]'`" ]] && isJoinedToDomain="TRUE" || isJoinedToDomain="FALSE"

if [[ "$isJoined" == "TRUE" && "$isJoinedToDomain" == "TRUE" ]]; then
  echo "Already joined to ActiveDirectory domain '$adDNSDomain'."
  exit
fi

if [[ "$isJoined" == "TRUE" && "$isJoinedToDomain" == "FALSE" ]]; then
  ## add code to remove from domain if $leaveCurrentDomain is TRUE
  # if [[ "$leaveCurrentDomain" == "FALSE" ]]; then
    
    echo "Cannot join '$adDNSDomain'. Currently joined to domain '$currentDomain'" >&2
    exit 1
  # fi
fi

echo "midclt call activedirectory.update \"{ \"domainname\":\"$adDNSDomain\",\"bindname\":\"$adNetBIOSDomain\\\\$adJoinUser\",\"bindpw\":\"$adJoinPwd\",\"allow_dns_updates\":true,\"createcomputer\":\"$adServerOU\",\"enable\":true }\""
adJoinReturn=`midclt call activedirectory.update "{ \"domainname\":\"$adDNSDomain\",\"bindname\":\"$adJoinUser\",\"bindpw\":\"$adJoinPwd\",\"allow_dns_updates\":true,\"createcomputer\":\"$adServerOU\",\"enable\":true }"`
## remove traces of command that includes password from zsh history
for historyNum in `history | awk '/midclt call activedirectory\.update/ {print $1}'`; do
  history -d $historyNum > /dev/null
done

adJoinJobId=`echo "$adJoinReturn" | jq -M '.job_id' 2>/dev/null`
if [[ -z "$adJoinJobId" ]]; then
  echo "$adJoinReturn" >&2
  exit 1
fi

while [[ -z "$(echo "$adJoinJobDetails" | jq '.[]|select(.progress.percent==100 or .state=="FAILED")')" ]]; do 
  sleep 1;
  adJoinJobDetails=`midclt call core.get_jobs "[[\"id\",\"=\",$adJoinJobId]]"`
done

if [[ -n "`echo "$adJoinJobDetails" | jq '.[]|select(.state=="FAILED")'`" ]]; then
  echo "Error joining active directory domiain '$adDNSDomain': `midclt call core.get_jobs "[[\\"id\\",\\"=\\",$adJoinJobId]]" | jq -rM '.[]|.error'`" >&2
  exit 1
else
  echo "Successfully joined ActiveDirectory."
fi
