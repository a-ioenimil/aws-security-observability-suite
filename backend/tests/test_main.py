from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello World"}

def test_read_whoami():
    response = client.get("/whoami/")
    assert response.status_code == 200
    assert response.json() == {"message": "I am the low-level guy who has been part of training frontier AI models from Anthropic and OpenAI on agentic reasoning."}
