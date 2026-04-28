from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict
import ollama
import uvicorn
import os

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
client = ollama.Client(host=OLLAMA_HOST)

class ChatRequest(BaseModel):
    message: str
    history: List[Dict[str, str]] = []

@app.post("/chat")
async def chat(request: ChatRequest):
    user_message = request.message
    history = request.history

    if not user_message:
        raise HTTPException(status_code=400, detail="No message provided")

    # Define system prompt for structured output
    system_prompt = {
        "role": "system",
        "content": (
            "You are a professional AI assistant. "
            "When asked for code (like Dockerfiles, Python, etc.), ALWAYS format it clearly using Markdown code blocks (```language ... ```). "
            "Provide the code first, then a brief explanation. "
            "Keep the response structured and professional."
        )
    }

    # Prepare messages for Ollama
    messages = [system_prompt]
    messages.extend([msg for msg in history if msg.get('role') in ['user', 'assistant']])
    messages.append({"role": "user", "content": user_message})

    async def generate():
        try:
            stream = client.chat(
                model='llama3.2:latest',
                messages=messages,
                stream=True
            )
            for chunk in stream:
                if 'message' in chunk and 'content' in chunk['message']:
                    yield chunk['message']['content']
        except Exception as e:
            yield f"Error: {str(e)}"

    return StreamingResponse(generate(), media_type="text/plain")

if __name__ == '__main__':
    uvicorn.run(app, host="0.0.0.0", port=5000)
