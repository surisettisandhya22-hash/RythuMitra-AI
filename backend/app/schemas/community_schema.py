from pydantic import BaseModel, Field
from typing import List, Optional

class CommunityComment(BaseModel):
    id: str
    author: str
    avatarColor: Optional[str] = "green"
    time: str
    text: str
    likes: int = 0

class CommunityPost(BaseModel):
    id: str
    title: str
    crop: str
    category: str = Field(..., description="Discussion, Question, Scheme, or SuccessStory")
    author: str
    location: str
    time: str
    content: str
    likes: int = 0
    isLiked: bool = False
    commentsCount: int = 0
    comments: List[CommunityComment] = Field(default_factory=list)
    aiVerifiedTip: Optional[str] = Field(None, description="RythuMitra AI Agronomist verification note")

class CreatePostRequest(BaseModel):
    title: str
    crop: str
    category: str = "Discussion"
    author: str = "Farmer"
    location: Optional[str] = "Andhra Pradesh"
    content: str

class AddCommentRequest(BaseModel):
    author: str = "Farmer"
    text: str

class AgronomistExpert(BaseModel):
    id: str
    name: str
    title: str
    specialization: str
    experience: str
    languages: List[str]
    phone: Optional[str] = None
    availableHours: str
    rating: float
