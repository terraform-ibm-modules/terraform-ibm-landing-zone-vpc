#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "=============================================================="
echo "   SLZ VPC v3 → v4 Migration Script (Subnet Key Migration)"
echo "=============================================================="
echo ""

STATE_JSON=$(terraform show -json 2>/dev/null || true)

if [[ -z "$STATE_JSON" || "$STATE_JSON" == "null" ]]; then
    echo "❌ ERROR: Terraform state could not be loaded."
    echo "Run this from the directory containing terraform.tfstate."
    exit 1
fi

###############################################
# Helper: Extract resources from module.slz_vpc
###############################################
extract_resources() {
    echo "$STATE_JSON" | jq -r '
        .values.root_module.child_modules[]
        | select(.address == "module.slz_vpc")
        | .resources[]
    '
}

echo "🔍 Scanning state for SLZ VPC subnets..."
SUBNETS=$(extract_resources | jq -r '
    select(.type == "ibm_is_subnet")
    | .address
')

echo "🔍 Scanning state for SLZ VPC address prefixes..."
PREFIXES=$(extract_resources | jq -r '
    select(.type == "ibm_is_vpc_address_prefix")
    | .address
')

if [[ -z "$SUBNETS" ]]; then
    echo "❌ No SLZ subnets found in state. Nothing to migrate."
    exit 1
fi

echo ""
echo "Found subnet resources:"
echo "$SUBNETS"
echo ""

###############################################
# Determine new keys
# Old key example: test25-vpc-subnet-a
# New key example: 1-subnet-a
###############################################

generate_new_key() {
    local old="$1"
    # old key always ends with "-subnet-a" or "-subnet-b"
    # extract letter
    local letter=$(echo "$old" | sed -E 's/.*subnet-([a-z])/\1/')
    
    # extract zone number from index inside subnet resource
    local zone=$(echo "$STATE_JSON" | jq -r \
        --arg old "$old" '
        .values.root_module.child_modules[]
        | select(.address == "module.slz_vpc")
        | .resources[]
        | select(.type == "ibm_is_subnet")
        | select(.address | endswith($old + "\"]"))
        | .values.zone
    ')

    # zone returned as "us-south-1" → extract trailing number
    local zone_num=$(echo "$zone" | sed -E 's/.*-([0-9]+)$/\1/')

    echo "${zone_num}-subnet-${letter}"
}

###############################################
# Build migration commands
###############################################

MOVED_COMMANDS=()

echo "🛠 Generating terraform state mv commands..."
echo ""

for subnet in $SUBNETS; do
    OLD_KEY=$(echo "$subnet" | sed -E 's/.*subnet\["([^"]+)"\].*/\1/')
    NEW_KEY=$(generate_new_key "$OLD_KEY")

    echo "➡ Subnet: $OLD_KEY → $NEW_KEY"

    MOVED_COMMANDS+=("terraform state mv \"module.slz_vpc.ibm_is_subnet.subnet[\\\"$OLD_KEY\\\"]\" \"module.slz_vpc.ibm_is_subnet.subnet[\\\"$NEW_KEY\\\"]\"")

    # same for prefix
    MOVED_COMMANDS+=("terraform state mv \"module.slz_vpc.ibm_is_vpc_address_prefix.subnet_prefix[\\\"$OLD_KEY\\\"]\" \"module.slz_vpc.ibm_is_vpc_address_prefix.subnet_prefix[\\\"$NEW_KEY\\\"]\"")
done

echo ""
echo "=============================================================="
echo "Generated Migration Commands"
echo "=============================================================="
printf "%s\n" "${MOVED_COMMANDS[@]}"
echo ""

###############################################
# Confirm and apply
###############################################

read -p "Apply these migration commands? (y/N): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "❌ Migration aborted by user."
    exit 0
fi

echo ""
echo "🚀 Applying migration..."
for cmd in "${MOVED_COMMANDS[@]}"; do
    echo "Running: $cmd"
    eval $cmd
done

echo ""
echo "✅ Migration completed successfully!"
echo "Run: terraform plan (should show NO subnet recreation)"
