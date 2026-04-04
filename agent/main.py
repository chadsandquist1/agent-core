from bedrock_agentcore import BedrockAgentCoreApp
from strands import Agent

KNOWLEDGE = """
- AWS Bedrock AgentCore is a managed serverless runtime for AI agents.
- It supports Python 3.10-3.13 via direct code deployment (ZIP files, no Docker).
- Agents are invoked via HTTP POST to /invocations with a JSON payload.
- The bedrock-agentcore SDK wraps your code in a managed HTTP server.
- Strands Agents is AWS's open-source agent framework built for Bedrock.
- Local testing uses: agentcore dev (starts server on localhost:8080)
"""

app = BedrockAgentCoreApp()

agent = Agent(
    model="us.anthropic.claude-3-5-haiku-20241022-v1:0",
    system_prompt=(
        "You are a helpful assistant. Answer questions using only this knowledge:\n"
        + KNOWLEDGE
        + "\nIf the answer is not in the knowledge base, say so."
    )
)


@app.entrypoint
async def invoke(payload):
    question = payload.get("prompt", "Hello")
    async for chunk in agent.stream_async(question):
        yield chunk


if __name__ == "__main__":
    app.run()
