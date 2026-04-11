import boto3
import json
import os
import sys
from botocore.config import Config


def invoke(agent_arn, question):
    config = Config(read_timeout=300, connect_timeout=60)
    client = boto3.client("bedrock-agentcore", region_name="us-east-1", config=config)
    response = client.invoke_agent_runtime(
        agentRuntimeArn=agent_arn,
        runtimeSessionId="hello-world-session-00000000000000",
        payload=json.dumps({"prompt": question}).encode(),
    )
    stream = response.get("response")
    if stream:
        for chunk in stream.iter_chunks():
            if chunk:
                print(chunk.decode("utf-8", errors="replace"), end="", flush=True)
    print()


if __name__ == "__main__":
    arn = os.environ.get("AGENT_ARN") or (sys.argv[1] if len(sys.argv) > 1 else None)
    if not arn:
        print("Usage: AGENT_ARN=<arn> python invoke.py [question]")
        print("       python invoke.py <arn> [question]")
        sys.exit(1)
    q = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else "What is AgentCore?"
    invoke(arn, q)
