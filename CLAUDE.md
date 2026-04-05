# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

A starter template for deploying Python AI agents to **AWS Bedrock AgentCore** — AWS's managed serverless runtime for agents. Uses the Strands Agents framework with Claude models.

## Commands

### Build
```bash
bash scripts/build.sh
```
Bundles `agent/main.py` and its dependencies (from `agent/requirements.txt`) into `dist/agent.zip`.

### Deploy Infrastructure (first time or changes)
```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply
```

### Deploy/Update Agent Runtime
```bash
bash scripts/deploy-runtime.sh
```
Uploads `dist/agent.zip` to S3 and creates/updates the Bedrock AgentCore runtime via AWS CLI.

### Test the Deployed Agent
```bash
AGENT_ARN=<your-arn> python scripts/invoke.py "Your question here"
```

## Architecture

### Local → Cloud Flow
1. **`agent/main.py`** — The entire agent lives here. `BedrockAgentCoreApp` wraps a Strands `Agent` configured with a Claude model. The `invoke()` function (decorated with `@app.entrypoint`) is the handler called by the runtime.
2. **`scripts/build.sh`** — Packages the agent into `dist/agent.zip` for deployment.
3. **`terraform/`** — Provisions S3 (artifact storage), IAM role (Bedrock/S3/CloudWatch permissions), and uploads the artifact.
4. **`scripts/deploy-runtime.sh`** — Creates/updates the actual Bedrock AgentCore runtime pointing to the S3 artifact.

### How the Agent Works
- The `invoke()` entrypoint receives a `question` from the runtime payload
- It creates a Strands `Agent` with a system prompt and calls `agent.stream_async(question)`
- The response streams back to the caller
- Model is set in `agent/main.py` — currently `us.anthropic.claude-3-5-haiku-20241022-v1:0`

### Infrastructure (Terraform)
- `main.tf` — S3 bucket + artifact upload
- `iam.tf` — IAM execution role with least-privilege permissions
- `variables.tf` — Region defaults to `us-east-1`
- `outputs.tf` — Exports role ARN and account ID (needed by `deploy-runtime.sh`)

## CI/CD
- **`.github/workflows/claude-review.yml`** — Claude Code runs automated PR review (triggers on PRs and `@claude` comments)
- **`.github/workflows/secret-scan.yml`** — TruffleHog scans every push/PR for leaked credentials
