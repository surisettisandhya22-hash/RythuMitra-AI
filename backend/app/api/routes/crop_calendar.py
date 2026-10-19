from fastapi import APIRouter, Query
from app.schemas.crop_calendar_schema import CropCalendarResponse
from app.services.crop_calendar_service import CropCalendarService
from datetime import date

router = APIRouter()

@router.get("/plan", response_model=CropCalendarResponse)
def get_crop_calendar(
    crop: str = Query("tomato", description="Name of the crop e.g. paddy, chilli, cotton, tomato"),
    sowing_date: str = Query(default_factory=lambda: str(date.today()), description="Sowing or transplanting date (YYYY-MM-DD)")
):
    """
    Returns an ICAR-compliant stage-by-stage crop calendar with chronological tasks,
    fertilizer schedules, and pest advisories based on the crop's sowing date.
    """
    return CropCalendarService.get_crop_calendar(crop_name=crop, sowing_date_str=sowing_date)
