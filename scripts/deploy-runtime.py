#!/usr/bin/env python3
"""
Idempotent deploy of the AgentCore Runtime via boto3.
Creates on first run, updates on subsequent runs.
Run this after: terraform apply
"""
import json
import subprocess
import sys

REGION = "us-east-1"
RUNTIME_NAME = "hello_world_qa"

# Pull Terraform outputs
def tf_output(key):
    result = subprocess.run(
        ["terraform", "-chdir=terraform", "output", "-raw", key],
        capture_output=True, text=True, check=True
    )
    return result.stdout.strip()

role_arn   = tf_output("execution_role_arn")
account_id = tf_output("account_id")
s3_bucket  = f"bedrock-agentcore-code-{account_id}-{REGION}"
s3_prefix  = "hello-world/agent.zip"

print(f"Role ARN: {role_arn}")
print(f"S3 URI:   s3://{s3_bucket}/{s3_prefix}")
print()

import boto3
client = boto3.client("bedrock-agentcore-control", region_name=REGION)

artifact = {
    "codeConfiguration": {
        "code": {"s3": {"bucket": s3_bucket, "prefix": s3_prefix}},
        "entryPoint": ["main.invoke"],
        "runtime": "PYTHON_3_12",
    }
}
network = {"networkMode": "PUBLIC"}

# Check if runtime already exists
response = client.list_agent_runtimes()
existing_id = next(
    (r["agentRuntimeId"] for r in response.get("agentRuntimes", [])
     if r["agentRuntimeName"] == RUNTIME_NAME),
    None
)

if existing_id:
    print(f"Found existing runtime (id: {existing_id}) — updating...")
    result = client.update_agent_runtime(
        agentRuntimeId=existing_id,
        agentRuntimeArtifact=artifact,
        roleArn=role_arn,
        networkConfiguration=network,
    )
else:
    print("No existing runtime found — creating...")
    result = client.create_agent_runtime(
        agentRuntimeName=RUNTIME_NAME,
        agentRuntimeArtifact=artifact,
        roleArn=role_arn,
        networkConfiguration=network,
    )

arn = result["agentRuntimeArn"]
print(f"\nAgent Runtime ARN: {arn}")
print(f"\nInvoke with:")
print(f"  AGENT_ARN={arn} python scripts/invoke.py 'What is AgentCore?'")
