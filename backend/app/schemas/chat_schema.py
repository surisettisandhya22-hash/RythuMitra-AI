from pydantic import BaseModel, Field

from typing import Optional

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, description="The message from the user")
    language: str = Field(..., description="The language code (e.g., 'en', 'te', 'hi')")
    context: Optional[dict] = Field(None, description="Optional farm and farmer context")

class ChatResponse(BaseModel):
    success: bool = Field(..., description="Whether the request was successful")
    message: str = Field(..., description="The AI response text")
    language: str = Field(..., description="The language code used for the response")
