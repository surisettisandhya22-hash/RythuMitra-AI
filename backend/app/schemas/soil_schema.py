from pydantic import BaseModel, Field
from typing import List, Optional

class SoilDataInput(BaseModel):
    crop: Optional[str] = Field(None, description="Target crop to grow or currently growing")
    soilType: Optional[str] = Field(None, description="Type of soil (e.g. Red, Black, Sandy, Clay, Loamy)")
    ph: Optional[float] = Field(None, description="Soil pH value (0 - 14)")
    nitrogen: Optional[float] = Field(None, description="Nitrogen value in kg/ha or rating")
    phosphorus: Optional[float] = Field(None, description="Phosphorus value in kg/ha or rating")
    potassium: Optional[float] = Field(None, description="Potassium value in kg/ha or rating")
    organicCarbon: Optional[float] = Field(None, description="Organic Carbon percentage")
    electricalConductivity: Optional[float] = Field(None, description="EC in dS/m (Salinity)")
    languageId: str = Field("en", description="Preferred response language code (en, te, hi, etc.)")

class NutrientStatus(BaseModel):
    level: str = Field(..., description="Low, Optimal, High, or Unknown")
    observation: str = Field(..., description="Nutrient status assessment")

class SoilHealthAnalysisResponse(BaseModel):
    overallHealth: str = Field(..., description="Overall condition e.g. Good, Needs Conditioning, Deficient, Degraded")
    summary: str = Field(..., description="Farmer-friendly summary of the soil status")
    phAnalysis: Optional[str] = Field(None, description="pH interpretation (e.g. Acidic, Neutral, Alkaline)")
    nutrientAssessments: Optional[dict] = Field(None, description="NPK & Carbon assessments")
    conditioningRecommendations: List[str] = Field(default_factory=list, description="Soil amendments like Gypsum, Lime, Vermicompost, Biofertilizers")
    fertilizerPlan: List[str] = Field(default_factory=list, description="Recommended fertilizer application dosage and schedule")
    suitableCrops: List[str] = Field(default_factory=list, description="List of crops best suited for this soil condition")
    warningNotes: Optional[str] = Field(None, description="Important precautions or caution notes for the farmer")

class SoilGuideStep(BaseModel):
    stepNumber: int
    title: str
    description: str
    icon: str
    tips: List[str]

class SoilSamplingGuideResponse(BaseModel):
    title: str
    importance: str
    bestTiming: str
    steps: List[SoilGuideStep]
    dosAndDonts: dict
