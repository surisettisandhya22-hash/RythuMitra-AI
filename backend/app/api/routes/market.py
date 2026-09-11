from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from app.schemas.market import MarketResponse
from app.services.market_service import market_service
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/prices", response_model=MarketResponse)
async def get_market_prices(
    crop: str = Query(..., description="The name of the crop"),
    state: Optional[str] = Query(None, description="The state location"),
    district: Optional[str] = Query(None, description="The district location"),
    language: Optional[str] = Query("en", description="Requested language code")
):
    try:
        prices = await market_service.get_prices(crop=crop, state=state, district=district)
        
        if not prices:
            # We return empty array and success, the client handles empty as "Data Unavailable"
            return MarketResponse(data=[], status="success", message="No market price was found for this crop and selected location.")
            
        return MarketResponse(data=prices, status="success", message="Market prices retrieved successfully.")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching market prices: {e}")
        raise HTTPException(status_code=500, detail="Market information is temporarily unavailable.")
