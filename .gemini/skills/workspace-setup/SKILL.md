---
name: workspace-setup
description: Master skill to set up the complete local development environment. Boots a local Plane instance (Docker), configures Gemini Kanban MCP integrations, and installs project hooks. Trigger this when a user asks to deploy a local development environment, setup plane, or initialize the workspace.
---
# Workspace Setup Master Skill

This skill scaffolds a complete local development environment, deploys a self-hosted instance of Plane, configures Kanban MCP settings, and ensures project hooks are installed.

## Workflow Execution Steps

### 1. Check Prerequisites
Verify that Docker is installed by executing `docker --version`. If it is not installed, inform the user that Docker is required to run Plane and suggest they install it (e.g., using `curl -fsSL https://get.docker.com | sh` or following the official Docker documentation) before proceeding.

### 2. Determine Domain Name
Use the `run_shell_command` tool with `hostname -I | awk '{print $1}'` to find the local IP address. 
Use the `ask_user` tool to present this IP as the suggested default option for the local environment. Explicitly ask the user for a "Domain or IP" (e.g., "What domain or IP would you like to use? [Suggested: <LOCAL_IP>]"). Mention that this can be changed later. 

### 2. Scaffold and Deploy Plane (Phase 1)
Run the first phase of the setup script, which creates the Docker compose files, generates secrets, and spins up Plane.
```bash
bash .gemini/skills/workspace-setup/scripts/phase1_deploy.sh <DOMAIN_NAME>
```
*Note: Make sure to pass the domain name they chose as an argument.*

### 3. Prompt User for Workspace Slug and Plane API Key (Phase 2)
Plane is now booting. It takes 5-10 minutes for the database to migrate.

Use the `ask_user` tool to walk the user through the setup process and gather their credentials:

First, present the **Setup Instructions and ask for Workspace Slug**:
- **Header**: Workspace Slug
- **Question**: "Plane is booting at `http://<DOMAIN_NAME>:8085/god-mode/`. The database migration takes 5-10 minutes. 

Please follow these steps:
1. Wait a few minutes and refresh `http://<DOMAIN_NAME>:8085/god-mode/` until the screen appears.
2. You will be asked to create an account. Follow the prompts to configure God Mode.
3. Once configured, navigate to `http://<DOMAIN_NAME>:8085/` to create your personal account.
4. During account setup, you will be forced to create a workspace/project.

What is the 'Workspace Slug' you created during step 4? (Tip: The slug is the last part of the URL after you create the workspace, e.g., if the URL is `http://<DOMAIN_NAME>:8085/my-workspace/`, the slug is `my-workspace`)."
- **Options**: Provide a single text input for `KANBAN_PROJECT_SLUG`.

Then, ask for the **Plane API Key**:
- **Header**: Kanban Configuration
- **Question**: "Great. Now in Plane, click the top-right user menu (the icon with your initial/avatar), navigate to Settings -> Account -> Personal Access Token, and create an API Key. Paste the key here once ready."
- **Options**: Provide a single text input for `KANBAN_API_KEY`.

Finally, ask for the **Main Workspace URL**:
- **Header**: Main Workspace URL
- **Question**: "Please verify your main workspace URL. This is the URL you are using to access Plane."
- **Options**: Provide a single text input for `MAIN_WORKSPACE_URL` with a placeholder of `http://<DOMAIN_NAME>:8085`.

### 4. Configure Kanban and Hooks (Phase 3)
Once the user provides the `KANBAN_API_KEY`, `KANBAN_PROJECT_SLUG`, and `MAIN_WORKSPACE_URL`, execute the final setup phase:
```bash
bash .gemini/skills/workspace-setup/scripts/phase2_configure.sh "<MAIN_WORKSPACE_URL>" "<KANBAN_API_KEY>" "<KANBAN_PROJECT_SLUG>"
```

### 5. Install Agency Agents Submodule and Subagents
Execute the following commands to add the specialized agents to the repository:
```bash
git submodule add https://github.com/adamoutler/gemini-agency-agents.git
git submodule update --init --recursive
```
*After this, run the final setup phase to copy the orchestrator files:*
```bash
bash .gemini/skills/workspace-setup/scripts/phase3_agents.sh
```

**Next, ask the user where they want to install the agents:**
Use the `ask_user` tool:
- **Header**: Install Location
- **Question**: "Where would you like to install the 60+ Agency Agents? (Global is recommended so they are available in all workspaces)."
- **Options**:
  1. `Global (~/.gemini/agents)`
  2. `Local (.gemini/agents)`
  3. `Other` (Custom path)

Based on their choice, run the bundled installation script from the newly created submodule:
```bash
# If Global:
cd gemini-agency-agents && python3 .gemini/skills/setup-agents/scripts/install_agents.py ~/.gemini/agents
# If Local:
cd gemini-agency-agents && python3 .gemini/skills/setup-agents/scripts/install_agents.py ../.gemini/agents
# If Other: 
# (Expand ~ if necessary using a shell command or prepending the home directory path, then execute python3 with the path).
```

### 6. Finish and Verification
Before instructing the user to restart, verify that `"experimental": { "enableAgents": true }` exists in their `~/.gemini/settings.json`. You can check this by running `jq '.experimental.enableAgents' ~/.gemini/settings.json`. If it returns `true`, proceed. If it is missing or `false`, use a shell command to use `jq` to add/set `"experimental.enableAgents": true` in their global `~/.gemini/settings.json` file.

Instruct the user that the `.gemini/.env`, `.gemini/settings.json`, and agents have been installed. Tell them they MUST restart the Gemini CLI session for the new environment variables, the enableAgents flag, and MCP server settings to take effect.

**Output exactly this:**
> "I've activated the workspace and the agents! Please type `/skills reload` and `/agents reload` (or simply restart your CLI session) so I can load them into memory. Once you're done, let me know and we can verify it works!"

Wait for the user to respond that they have reloaded. Once they do, automatically trigger the `agents-orchestrator` to run a network check:
> "I will now ask the agents-orchestrator to verify that the departments are online."

*Call the `agents-orchestrator` tool with:*
`"Please run a quick availability check. Call EXACTLY ONE agent from each of the following 7 departments: 1. Design & UX, 2. Engineering, 3. Marketing, 4. Product & Project Management, 5. Support & Operations, 6. Testing & Quality, and 7. Spatial Computing. Ask them: 'Are you available and online?'. Strictly instruct them NOT to execute any file operations, shell commands, or real tasks. Simply collect their natural, persona-driven responses to your question and report them back to me."`
