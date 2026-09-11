from pydantic import BaseModel, Field
from typing import List, Optional

class ScanAnalysisResult(BaseModel):
    summary: str = Field(..., description="A short farmer-friendly summary of the observation")
    possibleIssues: List[str] = Field(..., description="List of possible issues, keeping uncertainty in mind")
    visibleSymptoms: List[str] = Field(..., description="List of clearly visible symptoms in the image")
    recommendedNextSteps: List[str] = Field(..., description="List of practical next steps the farmer can take to verify or mitigate the issue")
    whenToSeekExpertHelp: str = Field(..., description="Advice on when to consult a qualified agricultural expert")
