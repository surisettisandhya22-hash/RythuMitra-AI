from pydantic import BaseModel, Field
from typing import List, Optional

class TreatmentOptions(BaseModel):
    organicTreatment: Optional[List[str]] = Field(default_factory=list, description="Organic/biological remedies (e.g. Neem oil, Trichoderma, Beauveria)")
    chemicalTreatment: Optional[List[str]] = Field(default_factory=list, description="Approved fungicides or insecticides with standard dosage guidelines")
    preventiveMeasures: Optional[List[str]] = Field(default_factory=list, description="Cultural & preventive practices (crop rotation, spacing, sanitation)")

class ScanAnalysisResult(BaseModel):
    cropName: Optional[str] = Field(None, description="The identified or inferred name of the crop, if applicable.")
    severityLevel: Optional[str] = Field("Moderate", description="Low, Moderate, High, or Severe")
    confidenceScore: Optional[str] = Field("85%", description="Approximate AI diagnostic confidence rating")
    summary: str = Field(..., description="A short farmer-friendly summary of the observation")
    possibleIssues: List[str] = Field(..., description="List of possible issues, keeping uncertainty in mind")
    visibleSymptoms: List[str] = Field(..., description="List of clearly visible symptoms in the image")
    treatmentOptions: Optional[TreatmentOptions] = Field(None, description="Detailed organic & chemical remedy options")
    recommendedNextSteps: List[str] = Field(..., description="List of practical next steps the farmer can take")
    whenToSeekExpertHelp: str = Field(..., description="Advice on when to consult a qualified agricultural expert")
