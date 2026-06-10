#!/bin/bash
# Deploy Godot client to Mac
# Usage: ./deploy_godot_client.sh [mac_ip] [mac_user]

MAC_IP="${1:-}"
MAC_USER="${2:-}"

echo "=== Dark World — Godot Client Deploy ==="

if [ -z "$MAC_IP" ]; then
    echo "Deploy files are in: /opt/darkworld/godot-client/"
    echo ""
    echo "To download to Mac, run ON YOUR MAC:"
    echo "  mkdir -p ~/Projects/darkworld"
    echo "  scp -r root@5.78.142.138:/opt/darkworld/godot-client/ ~/Projects/darkworld/"
    echo "  open ~/Projects/darkworld/godot-client/project.godot"
    exit 0
fi

echo "Deploying to ${MAC_USER}@${MAC_IP}..."
rsync -avz --delete /opt/darkworld/godot-client/ "${MAC_USER}@${MAC_IP}:~/Projects/darkworld/godot-client/"
echo "Done. Open on Mac: ~/Projects/darkworld/godot-client/project.godot"
