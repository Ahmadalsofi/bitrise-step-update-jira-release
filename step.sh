#!/bin/bash

# Function to check if a variable is empty
check_empty() {
  if [[ -z "$1" ]]; then
    echo "Error: $2 is required but not provided."
    exit 1
  fi
}

# Check mandatory inputs
check_empty "$jira_username" "Jira Username"
check_empty "$jira_token" "Jira API Token"
check_empty "$jira_url" "Jira URL"
check_empty "$jira_release_id" "Jira Release ID"
check_empty "$release_status" "Mark Release as Completed"

echo "Updating release..."

# Construct JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "id": "$jira_release_id",
  "released": "$release_status"
EOF
)

# Include releaseDate field if it's not empty
if [[ -n "$release_date" ]]; then
  JSON_PAYLOAD+=$',\n  "releaseDate": "'"$release_date"'"'
fi

JSON_PAYLOAD+=$'\n}'

# Send the request
RESPONSE=$(curl -s -X PUT -u "$jira_username:$jira_token" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "$jira_url/rest/api/3/version/$jira_release_id")

# Define color codes for terminal output
red=$'\e[31m'
green=$'\e[32m'
reset=$'\e[0m'

echo $RESPONSE
# Check if the Jira release update was successful or failed
if [[ $RESPONSE == *"errorMessages"* ]]; then
  echo "${red}❗️ Failed $RESPONSE ${reset}"
  envman add --key JIRA_RELEASE_UPDATE_SUCCESS --value false
  exit -1
else
  # If the update was successful, mark it as successful
  name="$(echo $RESPONSE | jq '.name' | tr -d '"')"
  variable=$( [ "$release_status" = true ] && echo "release" || echo "draft" )
  echo "${green}✅ Success!${reset} $name release has been updated to $variable"
  envman add --key JIRA_RELEASE_UPDATE_SUCCESS --value true
  exit 0
fi
