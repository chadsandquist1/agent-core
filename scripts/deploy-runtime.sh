#!/usr/bin/env bash
# Idempotent deploy of the AgentCore Runtime via AWS CLI.
# Creates on first run, updates on subsequent runs.
# Run this after: terraform apply
set -euo pipefail

REGION="us-east-1"
RUNTIME_NAME="hello-world-qa"
TF_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"

ROLE_ARN=$(cd "$TF_DIR" && terraform output -raw execution_role_arn)
ACCOUNT_ID=$(cd "$TF_DIR" && terraform output -raw account_id)
S3_URI="s3://bedrock-agentcore-code-${ACCOUNT_ID}-${REGION}/hello-world/agent.zip"

echo "Role ARN:  $ROLE_ARN"
echo "S3 URI:    $S3_URI"
echo ""

ARTIFACT='{
  "codeConfiguration": {
    "s3Uri": "'"$S3_URI"'",
    "entrypoint": "main.py",
    "runtime": "PYTHON_3_12"
  }
}'

# Check if a runtime with this name already exists
EXISTING_ID=$(aws bedrock-agentcore list-agent-runtimes \
  --region "$REGION" \
  --output json \
  | python3 -c "
import sys, json
runtimes = json.load(sys.stdin).get('agentRuntimes', [])
match = next((r['agentRuntimeId'] for r in runtimes if r['agentRuntimeName'] == '$RUNTIME_NAME'), '')
print(match)
")

if [ -n "$EXISTING_ID" ]; then
  echo "Found existing runtime (id: $EXISTING_ID) — updating..."
  RESULT=$(aws bedrock-agentcore update-agent-runtime \
    --region "$REGION" \
    --agent-runtime-id "$EXISTING_ID" \
    --agent-runtime-artifact "$ARTIFACT" \
    --role-arn "$ROLE_ARN" \
    --network-configuration '{"networkMode": "PUBLIC"}' \
    --output json)
else
  echo "No existing runtime found — creating..."
  RESULT=$(aws bedrock-agentcore create-agent-runtime \
    --region "$REGION" \
    --agent-runtime-name "$RUNTIME_NAME" \
    --agent-runtime-artifact "$ARTIFACT" \
    --role-arn "$ROLE_ARN" \
    --network-configuration '{"networkMode": "PUBLIC"}' \
    --output json)
fi

echo "$RESULT"

AGENT_ARN=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['agentRuntimeArn'])")
echo ""
echo "Agent Runtime ARN: $AGENT_ARN"
echo ""
echo "Invoke with:"
echo "  AGENT_ARN=$AGENT_ARN python scripts/invoke.py 'What is AgentCore?'"
