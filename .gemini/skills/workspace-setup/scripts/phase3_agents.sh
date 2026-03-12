#!/bin/bash
set -e

# Check for required submodule
if [ ! -f "gemini-agency-agents/specialized/agents-orchestrator.md" ]; then
    echo "Error: The gemini-agency-agents submodule is missing."
    echo "Please ensure you have run:"
    echo "  git submodule add https://github.com/adamoutler/gemini-agency-agents.git"
    echo "  git submodule update --init --recursive"
    exit 1
fi

mkdir -p template/.gemini/hooks

# Copy hooks
cp -r .gemini/skills/workspace-setup/assets/hooks/* template/.gemini/hooks/
chmod +x template/.gemini/hooks/*

# Copy base orchestrator from the local submodule and append kanban rules
mkdir -p template/.gemini/agents
mkdir -p template/.gemini/tools
mkdir -p template/.gemini/prompts

cp gemini-agency-agents/specialized/agents-orchestrator.md template/.gemini/agents/agents-orchestrator.md
cp .gemini/skills/workspace-setup/assets/kanban-addendum.md template/.gemini/tools/kanban.md

# Create project-specific prompts file
cat << 'PROMPT_EOF' > template/.gemini/prompts/project-specific.md
## Project Specific Information
Add your project-specific information and architectural rules here.
PROMPT_EOF

# Create main GEMINI.md template
cat << 'GEMINI_EOF' > template/.gemini/GEMINI.md
@agents/agents-orchestrator.md
@tools/kanban.md
@prompts/project-specific.md
GEMINI_EOF

# (settings.json is now handled in phase2_configure.sh)

# Create README.md
cat << 'EOF' > template/README.md
# Local Development Environment Setup

This folder contains a fully containerized deployment of Plane and a template for your Gemini projects to interact with it.

## 1. Deploy Plane
1. Navigate to `plane/` (located in the parent directory).
2. Run `docker compose up -d`.
3. Plane will be available at your specified domain or localhost (port 8085).

## 2. Setup Project Context
To use this setup, implement the generated kanban rules and project hooks into your working directory:
1. Copy the entire generated `.gemini` template to the root of your project: `cp -r template/.gemini/* .gemini/`
2. Add your own project-specific information and architectural rules in `.gemini/prompts/project-specific.md`.

This ensures that the @agents-orchestrator rules, QA gates, and commit interception logic are strictly enforced by Gemini CLI for this specific repository.
EOF

echo "Agents and workspace templates successfully compiled!"
