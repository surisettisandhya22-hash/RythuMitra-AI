from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from app.schemas.irrigation_schema import (
    IrrigationCalculationRequest,
    IrrigationAdviceResponse,
)
from app.services.irrigation_service import irrigation_service

router = APIRouter()

@router.post("/calculate", response_model=IrrigationAdviceResponse)
def calculate_irrigation_advice(req: IrrigationCalculationRequest):
    """
    Computes precise evapotranspiration-based water volume (ETc), pump run-times,
    soil moisture status, rain-delay advisories, 7-day schedule, and micro-irrigation comparisons.
    """
    try:
        return irrigation_service.calculate_irrigation_advice(req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/methods")
def get_supported_irrigation_methods():
    """
    Returns supported irrigation methods and typical efficiency ratings.
    """
    return [
        {"id": "drip", "name": "Drip Irrigation", "efficiency": "90%", "subsidyAvailable": True},
        {"id": "sprinkler", "name": "Sprinkler", "efficiency": "75%", "subsidyAvailable": True},
        {"id": "awd", "name": "AWD (Alternate Wetting & Drying)", "efficiency": "72%", "subsidyAvailable": False},
        {"id": "furrow", "name": "Flood / Furrow", "efficiency": "50%", "subsidyAvailable": False},
    ]
