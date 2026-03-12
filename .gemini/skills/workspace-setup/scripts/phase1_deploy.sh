#!/bin/bash
set -e

DOMAIN_NAME=${1:-localhost}

echo "Setting up development environment with domain: $DOMAIN_NAME"

# Create output directories
mkdir -p plane
mkdir -p template/.gemini/hooks

# Generate secrets if .env doesn't exist
if [ ! -f plane/.env ]; then
  PGPASSWORD=$(openssl rand -hex 16)
  AWS_SECRET_ACCESS_KEY=$(openssl rand -hex 32)
  SECRET_KEY=$(openssl rand -hex 32)
  PLANE_API_KEY="plane_api_$(openssl rand -hex 16)"
  WORKSPACE_SLUG="dev-env"

  cat << EOF > plane/.env
DOMAIN_NAME=$DOMAIN_NAME
WEB_URL=http://${DOMAIN_NAME}:8085
APP_BASE_URL=http://${DOMAIN_NAME}:8085
ADMIN_BASE_URL=http://${DOMAIN_NAME}:8085
CORS_ALLOWED_ORIGINS=http://${DOMAIN_NAME}:8085
PROTOCOL=http
APP_PROTOCOL=http
MINIO_ENDPOINT_SSL=0
PGPASSWORD=$PGPASSWORD
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
SECRET_KEY=$SECRET_KEY
PLANE_API_KEY=$PLANE_API_KEY
WORKSPACE_SLUG=$WORKSPACE_SLUG
EOF
  echo "Generated new secrets in plane/.env"
else
  echo "Using existing .env file in plane"
  # Update DOMAIN_NAME in existing .env
  sed -i "s/^DOMAIN_NAME=.*/DOMAIN_NAME=$DOMAIN_NAME/g" plane/.env
fi

# Copy docker-compose template directly
cp .gemini/skills/workspace-setup/assets/docker-compose-template.yml plane/docker-compose.yml

sed -i "s|https://\${DOMAIN_NAME}/mcp/http|https://\${DOMAIN_NAME}/mcp/http|g" plane/docker-compose.yml

# Copy Caddyfile
cp .gemini/skills/workspace-setup/assets/Caddyfile.fixed plane/Caddyfile.fixed

echo "Starting Docker Compose for Plane..."
cd plane
docker compose up -d

echo "Plane deployment initiated. It may take 5-10 minutes for the database to fully migrate."
