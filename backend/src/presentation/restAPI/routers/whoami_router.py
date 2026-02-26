from fastapi import APIRouter

whoami_router = APIRouter(prefix="/whoami", tags=["whoami"])

@whoami_router.get("/")
async def whoami():
    return {"message": "I am the low-level guy who has been part of training frontier AI models from Anthropic and OpenAI on agentic reasoning."}
