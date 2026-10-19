from pydantic import BaseModel, Field
from typing import List, Optional, Dict

class IrrigationCalculationRequest(BaseModel):
    crop: str = Field(..., description="Crop name, e.g. 'Rice / Paddy', 'Cotton', 'Chilli', 'Maize', 'Groundnut', etc.")
    area: float = Field(..., gt=0, description="Farm area, must be > 0")
    unit: str = Field("Acres", description="'Acres', 'Hectares', or 'Guntas'")
    growthStage: str = Field("Vegetative", description="'Initial / Seedling', 'Vegetative', 'Flowering / Critical', 'Maturity / Ripening'")
    soilType: str = Field("Red Sandy Loam", description="'Black Clay Soil', 'Red Sandy Loam', 'Clay Loam', 'Sandy Soil'")
    irrigationMethod: str = Field("Drip Irrigation", description="'Drip Irrigation', 'Sprinkler', 'Flood / Furrow', 'AWD (Alternate Wetting & Drying)'")
    pumpHorsepower: float = Field(5.0, description="Motor pump HP (e.g. 3.0, 5.0, 7.5)")
    rainForecastMm: float = Field(0.0, description="Forecasted rainfall in next 48h in mm")
    languageId: str = Field("en", description="Language: 'en', 'te', 'hi'")

class IrrigationScheduleItem(BaseModel):
    dayOffset: int
    dayName: str
    dateFormatted: str
    shouldIrrigate: bool
    recommendedRunTimeMinutes: int
    waterVolumeLiters: float
    actionSummary: str
    weatherSyncNote: str

class IrrigationMethodComparison(BaseModel):
    method: str
    localMethodName: str
    waterEfficiencyPercent: int
    waterLitersPerAcrePerDay: float
    pumpRunHours: float
    waterSavingsPercent: int
    fertigationSupported: bool
    keyRecommendation: str

class IrrigationAdviceResponse(BaseModel):
    crop: str
    cropLocalName: str
    area: float
    unit: str
    areaInAcres: float
    growthStage: str
    soilType: str
    irrigationMethod: str
    soilMoistureStatus: str  # 'Optimal', 'Needs Water', 'Critical Stress', 'Saturated'
    estimatedSoilMoisturePercent: int
    shouldIrrigateToday: bool
    dailyWaterRequirementLiters: float
    dailyWaterRequirementPerAcreLiters: float
    pumpRuntimeMinutes: int
    irrigationIntervalDays: int
    summary: str
    weatherSyncNotice: str
    bestTimeToIrrigate: str
    sevenDaySchedule: List[IrrigationScheduleItem]
    methodsComparison: List[IrrigationMethodComparison]
    criticalStages: List[str]
    waterSavingTips: List[str]
    subsidyInfo: Dict[str, str]
