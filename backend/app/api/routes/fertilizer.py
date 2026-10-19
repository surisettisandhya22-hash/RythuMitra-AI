from fastapi import APIRouter, HTTPException
from typing import List
from app.schemas.fertilizer_schema import (
    FertilizerCalculationRequest,
    FertilizerRecommendationResponse,
    SupportedCropItem,
)
from app.services.fertilizer_service import fertilizer_service

router = APIRouter()

@router.get("/crops", response_model=List[SupportedCropItem])
def get_supported_crops():
    """
    Returns list of supported agricultural crops with regional names and metadata.
    """
    try:
        return fertilizer_service.get_supported_crops()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/calculate", response_model=FertilizerRecommendationResponse)
def calculate_fertilizer_recommendation(req: FertilizerCalculationRequest):
    """
    Computes a comprehensive scientific fertilizer schedule, commercial bag requirements,
    estimated subsidized costs, stage-wise splits, organic alternatives, and micronutrients.
    """
    try:
        return fertilizer_service.calculate_fertilizer_plan(req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
