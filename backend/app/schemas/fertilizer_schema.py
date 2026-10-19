from pydantic import BaseModel, Field
from typing import List, Optional, Dict

class FertilizerCalculationRequest(BaseModel):
    crop: str = Field(..., description="Crop name (e.g. 'Rice / Paddy', 'Cotton', 'Chilli', 'Maize', etc.)")
    area: float = Field(..., gt=0, description="Farm area size, must be greater than 0")
    unit: str = Field("Acres", description="Area unit: 'Acres', 'Hectares', or 'Guntas'")
    farmingType: str = Field("Integrated", description="'Integrated' (Chemical + Organic) or 'Organic'")
    soilType: Optional[str] = Field(None, description="Optional soil type (e.g. 'Black Soil', 'Red Sandy Loam', 'Clay')")
    languageId: str = Field("en", description="Language code: 'en', 'te', 'hi', etc.")

class FertilizerBagItem(BaseModel):
    name: str = Field(..., description="Standard product name, e.g. 'Urea (46% N)'")
    localName: str = Field(..., description="Regional name, e.g. 'యూరియా'")
    nutrientType: str = Field(..., description="Nutrient role: 'Nitrogen (N)', 'Phosphorus (P)', 'Potassium (K)', etc.")
    quantityKg: float = Field(..., description="Total quantity required in kilograms")
    bagsCount: float = Field(..., description="Number of standard bags needed")
    bagWeightKg: int = Field(..., description="Standard bag weight (45kg for Urea, 50kg for DAP/MOP/SSP)")
    looseKgRemaining: float = Field(0.0, description="Remaining loose kg beyond full bags")
    estimatedPricePerBag: float = Field(..., description="Government subsidized price estimate per bag in INR")
    totalEstimatedPrice: float = Field(..., description="Total cost estimate for this fertilizer in INR")
    applicationGuide: str = Field(..., description="Usage instructions, placement, and safety")

class StageFertilizerDose(BaseModel):
    productName: str
    quantityKg: float
    bagsApprox: str
    instruction: str

class GrowthStageScheduleItem(BaseModel):
    stageName: str = Field(..., description="Growth stage name, e.g. 'Basal / ఆఖరి దుక్కిలో'")
    timingDays: str = Field(..., description="Timing relative to sowing/transplanting, e.g. 'Day 0 (At Sowing)'")
    description: str = Field(..., description="Explanation of crop requirements at this stage")
    fertilizers: List[StageFertilizerDose] = Field(default_factory=list, description="Fertilizers to apply at this specific stage")
    waterPrecaution: str = Field(..., description="Moisture condition and irrigation advice during application")

class OrganicAlternativeItem(BaseModel):
    name: str = Field(..., description="Organic amendment, e.g. 'Vermicompost', 'Jeevamrutham'")
    localName: str = Field(..., description="Regional name, e.g. 'వానపాముల ఎరువు', 'జీవామృతం'")
    quantityPerAcre: str = Field(..., description="Recommended dosage per acre")
    benefits: str = Field(..., description="Agronomic benefits to soil microbiology and yield")
    applicationMethod: str = Field(..., description="How to prepare or apply to soil/foliage")

class MicronutrientItem(BaseModel):
    nutrient: str = Field(..., description="Micronutrient name, e.g. 'Zinc (Zn)', 'Boron (B)'")
    importance: str = Field(..., description="Why this crop needs it")
    recommendedProduct: str = Field(..., description="Commercial formulation, e.g. 'Zinc Sulphate 21%'")
    dosagePerAcre: str = Field(..., description="Dosage in kg or grams per acre")
    applicationTiming: str = Field(..., description="Best growth stage to apply")

class FertilizerRecommendationResponse(BaseModel):
    crop: str
    cropLocalName: str
    area: float
    unit: str
    areaInAcres: float
    farmingType: str
    summary: str
    totalEstimatedCost: float
    primaryFertilizers: List[FertilizerBagItem]
    growthStageSchedule: List[GrowthStageScheduleItem]
    organicAlternatives: List[OrganicAlternativeItem]
    micronutrients: List[MicronutrientItem]
    bestPractices: List[str]
    warningNotes: str

class SupportedCropItem(BaseModel):
    id: str
    nameEn: str
    nameTe: str
    nameHi: str
    category: str
    icon: str
