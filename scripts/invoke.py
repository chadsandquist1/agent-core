import boto3
import json
import os
import sys


def invoke(agent_arn, question):
    client = boto3.client("bedrock-agentcore", region_name="us-east-1")
    response = client.invoke_agent_runtime(
        agentRuntimeArn=agent_arn,
        runtimeSessionId="hello-world-session",
        payload=json.dumps({"prompt": question}).encode(),
    )
    for event in response.get("body", []):
        chunk = event.get("chunk", {}).get("bytes", b"")
        if chunk:
            print(chunk.decode(), end="", flush=True)
    print()


if __name__ == "__main__":
    arn = os.environ.get("AGENT_ARN") or (sys.argv[1] if len(sys.argv) > 1 else None)
    if not arn:
        print("Usage: AGENT_ARN=<arn> python invoke.py [question]")
        print("       python invoke.py <arn> [question]")
        sys.exit(1)
    q = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else "What is AgentCore?"
    invoke(arn, q)
