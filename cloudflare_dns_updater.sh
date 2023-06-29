#!/bin/bash

source config.env

# Cloudflare API credentials
zone_identifier=$ZONE_IDENTIFIER
api_key=$API_KEY
cloudflare_account_email=$CLOUDFLARE_ACCOUNT_EMAIL

comment_update_time=$(date)
endpoint="https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/"


declare -A dns_names_ids
# Get all dns record names + ids for a zone
get_dns_records_for_zone() {
  echo "Getting list of DNS records for zone..."
  local response=$(curl -s -X GET "$endpoint" \
    -H 'Content-Type: application/json' \
    -H "X-Auth-Email: $cloudflare_account_email" \
    -H "X-Auth-Key: $api_key")

  # TODO CAN I REPLACE THIS WITH A BUILT IN UTIL SO I DON'T HAVE ANY EXTRA DEPENDENCIES, MAYBE AWK?
  local json=$(echo $response | jq '.result[] | select(.type == "A") | {name, id}')

  # Extract the name and id and store a k/v pair
  while read -r name id; do
    dns_names_ids["$name"]=$id
  done < <(echo "$json" | awk -F'"' '{ if ($2=="name") printf "%s ", $4; else if ($2=="id") printf "%s\n", $4 }')
}


# Get IP address for DNS record
get_cloudflare_dns_record_ip() {
  dns_record_identifier="$1"

  local response=$(curl -s -X GET "$endpoint"/"$dns_record_identifier" \
    -H 'Content-Type: application/json' \
    -H "X-Auth-Email: $cloudflare_account_email" \
    -H "X-Auth-Key: $api_key")

  # Extract IP address from API response
  local current_ip=$(echo "$response" | grep -oE '"content":"[0-9\.]+"' | cut -d ":" -f2 | tr -d '"')

  echo "$current_ip"
}

# Update the specified dns record with the correct public ip
update_dns_record() {
  public_ip=$1
  dns_record_name=$2
  dns_record_identifier=$3
  local data='{
    "type": "A",
    "comment": "Updated at: '"$comment_update_time"'",
    "name": "'"$dns_record_name"'",
    "proxied": true,
    "content": "'"$public_ip"'"
  }'

  # Send API request
  curl -s -X PUT "$endpoint"/"$dns_record_identifier" \
    -H 'Content-Type: application/json' \
    -H "X-Auth-Email: $cloudflare_account_email" \
    -H "X-Auth-Key: $api_key" \
    --data "$data"
}


public_ip=$(curl ifconfig.me)

get_dns_records_for_zone

# Iterate over each dns record and update if needed
for name in "${!dns_names_ids[@]}"; do
  id="${dns_names_ids[$name]}"
  dns_record_ip=$(get_cloudflare_dns_record_ip "$id")
  echo "Checking ip for $name record"
  if [[ "$dns_record_ip" == "$public_ip" ]]; then
    echo "No update needed"
  else
    echo "Public ip has changed, updating dns record $name"
    update_dns_record $public_ip $name $id
  fi
done
