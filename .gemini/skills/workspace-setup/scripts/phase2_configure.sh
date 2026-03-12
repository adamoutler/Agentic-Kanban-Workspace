#!/bin/bash
set -e

KANBAN_BASE_URL=$1
KANBAN_API_KEY=$2
KANBAN_PROJECT_SLUG=$3

if [ -z "$KANBAN_BASE_URL" ] || [ -z "$KANBAN_API_KEY" ] || [ -z "$KANBAN_PROJECT_SLUG" ]; then
    echo "Error: Missing arguments."
    echo "Usage: phase2_configure.sh <KANBAN_BASE_URL> <KANBAN_API_KEY> <KANBAN_PROJECT_SLUG>"
    exit 1
fi

if [[ ! "$KANBAN_API_KEY" == plane_api_* ]]; then
    echo "Error: The provided API key does not appear to be a valid Plane API Key."
    echo "It must start with 'plane_api_'. Please get a personal API key from your user settings."
    exit 1
fi

mkdir -p template/.gemini

# Write .env
cat << EOF > template/.gemini/.env
KANBAN_BASE_URL=$KANBAN_BASE_URL
KANBAN_API_KEY=$KANBAN_API_KEY
KANBAN_PROJECT_SLUG=$KANBAN_PROJECT_SLUG
EOF

# Write to ~/.bashrc
if ! grep -q "export KANBAN_API_KEY=" ~/.bashrc; then
    echo "export KANBAN_API_KEY=$KANBAN_API_KEY" >> ~/.bashrc
    echo "Added KANBAN_API_KEY to ~/.bashrc"
else
    sed -i "s/^export KANBAN_API_KEY=.*/export KANBAN_API_KEY=$KANBAN_API_KEY/" ~/.bashrc
    echo "Updated KANBAN_API_KEY in ~/.bashrc"
fi

echo "Created template/.gemini/.env with Kanban configuration."

# Update or create settings.json
if [ ! -f template/.gemini/settings.json ]; then
  if [ -f .gemini/skills/workspace-setup/assets/settings-template.json ]; then
    cp .gemini/skills/workspace-setup/assets/settings-template.json template/.gemini/settings.json
  else
    echo '{"mcpServers": {}}' > template/.gemini/settings.json
  fi
fi

# Make sure mcpServers object exists
if ! jq -e '.mcpServers' template/.gemini/settings.json >/dev/null 2>&1; then
  jq '.mcpServers = {}' template/.gemini/settings.json > template/.gemini/settings.json.tmp && mv template/.gemini/settings.json.tmp template/.gemini/settings.json
fi

# Use jq to update settings.json
jq --arg url "${KANBAN_BASE_URL}/mcp/http/api-key/mcp" \
   '.mcpServers.kanban = {url: $url, headers: {Authorization: "Bearer ${KANBAN_API_KEY}", "X-Workspace-slug": "${KANBAN_PROJECT_SLUG}"}}' \
   template/.gemini/settings.json > template/.gemini/settings.json.tmp && mv template/.gemini/settings.json.tmp template/.gemini/settings.json

echo "Updated template/.gemini/settings.json with 'kanban' MCP server configuration."
