#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "=============================================================="
echo "   SLZ VPC v3 → v4 Migration Script for IBM Schematics"
echo "=============================================================="

WORKSPACE_ID=""
REGION=""
RESOURCE_GROUP=""

while getopts "w:r:g:" opt; do
  case "$opt" in
    w) WORKSPACE_ID="$OPTARG" ;;
    r) REGION="$OPTARG" ;;
    g) RESOURCE_GROUP="$OPTARG" ;;
    *) ;;
  esac
done

if [[ -z "$WORKSPACE_ID" || -z "$REGION" ]]; then
  echo "❌ Usage: $0 -w WORKSPACE_ID -r REGION [-g RESOURCE_GROUP]"
  exit 1
fi

echo "Using:"
echo "  Workspace     : $WORKSPACE_ID"
echo "  Region        : $REGION"
echo "  Resource Group: ${RESOURCE_GROUP:-Default}"
echo ""

echo "🔐 Logging in..."
ibmcloud target -r "$REGION" >/dev/null

if [[ -n "$RESOURCE_GROUP" ]]; then
  ibmcloud target -g "$RESOURCE_GROUP" >/dev/null
fi

echo "🔍 Fetching remote Schematics state..."
STATE_JSON=$(ibmcloud schematics state pull -id "$WORKSPACE_ID")

if [[ -z "$STATE_JSON" ]]; then
  echo "❌ Could not retrieve workspace state"
  exit 1
fi

echo "🔍 Extracting subnet keys..."
SUBNET_KEYS=$(echo "$STATE_JSON" | jq -r '
  .resources[]?
  | select(.type=="ibm_is_subnet")
  | select(.module|contains("module.slz_vpc"))
  | .instances[].index_key
')

if [[ -z "$SUBNET_KEYS" ]]; then
  echo "❌ No SLZ VPC subnets found in workspace state."
  exit 1
fi

echo ""
echo "Found subnets:"
echo "$SUBNET_KEYS"
echo ""

echo "🛠 Generating migration commands..."
COMMANDS_FILE="schematics_migration.txt"
: > "$COMMANDS_FILE"

for OLD_KEY in $SUBNET_KEYS; do
  ZONE_SUFFIX=$(echo "$OLD_KEY" | awk -F '-' '{print $NF}')
  NEW_KEY="1-subnet-$ZONE_SUFFIX"

  printf '%s\n' \
    "ibmcloud schematics state mv -id \"$WORKSPACE_ID\" \"module.slz_vpc.ibm_is_subnet.subnet[\\\"$OLD_KEY\\\"]\" \"module.slz_vpc.ibm_is_subnet.subnet[\\\"$NEW_KEY\\\"]\"" \
    >> "$COMMANDS_FILE"

  printf '%s\n' \
    "ibmcloud schematics state mv -id \"$WORKSPACE_ID\" \"module.slz_vpc.ibm_is_vpc_address_prefix.subnet_prefix[\\\"$OLD_KEY\\\"]\" \"module.slz_vpc.ibm_is_vpc_address_prefix.subnet_prefix[\\\"$NEW_KEY\\\"]\"" \
    >> "$COMMANDS_FILE"
done

echo ""
echo "=============================================================="
echo "Generated Schematics Migration Commands"
echo "=============================================================="
cat "$COMMANDS_FILE"

echo ""
read -r -p "Apply these migration commands now? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ Migration cancelled."
  exit 0
fi

echo ""
echo "🚀 Applying migration..."
while IFS= read -r CMD; do
  echo "Running: $CMD"
  eval "$CMD"
done < "$COMMANDS_FILE"

echo ""
echo "✅ Migration completed successfully!"
echo "Run 'ibmcloud schematics plan -id $WORKSPACE_ID' to verify no subnets are recreated."
