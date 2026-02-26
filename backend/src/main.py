from fastapi import FastAPI

from src.presentation.restAPI.routers.whoami_router import whoami_router

app = FastAPI()

app.include_router(whoami_router)

@app.get("/")
async def root():
    return {"message": "Hello World"}