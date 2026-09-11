from fastapi import APIRouter, HTTPException
from app.schemas.chat_schema import ChatRequest, ChatResponse
from app.services.ai_service import ai_service

router = APIRouter()

@router.post("/v1/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    try:
        response_text = await ai_service.generate_chat_response(
            message=request.message,
            language_code=request.language,
            context=request.context
        )
        return ChatResponse(
            success=True,
            message=response_text,
            language=request.language
        )
    except Exception as e:
        error_msg = str(e)
        print(f"Chat route error: {error_msg}")
        if "API configuration is missing" in error_msg or "environment variable is not set" in error_msg or "API key not valid" in error_msg:
            raise HTTPException(status_code=503, detail="Missing AI API configuration")
        elif "Failed to generate response" in error_msg:
            raise HTTPException(status_code=502, detail="AI provider error")
        elif "Empty or invalid response" in error_msg:
            raise HTTPException(status_code=502, detail="Empty or invalid response from AI provider")
        else:
            raise HTTPException(status_code=500, detail="Unable to process the chat request")
