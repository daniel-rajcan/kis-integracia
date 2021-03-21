#!/bin/bash

USERNAME="${1}"
PASSWORD="${2}"
AUTH_URL="${3}"

AUTH_TOKEN=$(wget -S --no-check-certificate --quiet \
  --method POST \
  --timeout=0 \
  --header 'Content-Type: application/json' \
  --body-data "{
    \"auth\": {
        \"identity\": {
            \"methods\": [
                \"password\"
            ],
            \"password\": {
                \"user\": {
                    \"name\": \"${USERNAME}\",
                    \"domain\": {
                        \"name\": \"Default\"
                    },
                    \"password\": \"${PASSWORD}\"
                }
            }
        }
    }
}
" $AUTH_URL/v3/auth/tokens -O - 2>&1 | grep -Po "X-Subject-Token: \K.+")

ID=$(wget --no-check-certificate --quiet \
  --method GET \
  --timeout=0 \
  --header "X-Auth-Token: ${AUTH_TOKEN}" \
   http://10.0.0.25:9696/v2.0/networks -O - | jq '.networks[] | select(.name=="public") | . .id' | sed 's/"//g')

printf %s "${ID}" > ext_network_id
