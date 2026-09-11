import os
import httpx
from typing import List, Optional
from fastapi import HTTPException
from app.schemas.market import MarketPrice
import logging

logger = logging.getLogger(__name__)

class MarketService:
    def __init__(self):
        self.api_key = os.getenv("DATA_GOV_API_KEY")
        self.base_url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"

    def _normalize_crop(self, crop: str) -> str:
        # AGMARKNET expects exact commodity names.
        c = crop.lower().strip()
        mapping = {
            "rice": "Paddy(Dhan)(Common)",
            "paddy": "Paddy(Dhan)(Common)",
            "tomato": "Tomato",
            "chilli": "Green Chilli",
            "chili": "Green Chilli",
            "cotton": "Cotton",
            "maize": "Maize",
            "wheat": "Wheat",
            "onion": "Onion",
            "potato": "Potato"
        }
        return mapping.get(c, crop.title())

    async def get_prices(self, crop: str, state: Optional[str] = None, district: Optional[str] = None) -> List[MarketPrice]:
        if not self.api_key or self.api_key == "your_data_gov_api_key_here":
            raise HTTPException(status_code=503, detail="Market provider configuration is missing.")

        normalized_crop = self._normalize_crop(crop)
        
        url = f"{self.base_url}?api-key={self.api_key}&format=json&limit=10&filters[commodity]={normalized_crop}"
        if state:
            url += f"&filters[state]={state.title()}"
        if district:
            url += f"&filters[district]={district.title()}"

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, timeout=15.0)
                if response.status_code != 200:
                    logger.error(f"AGMARKNET API Error: {response.text}")
                    raise HTTPException(status_code=502, detail="Market provider is currently unavailable.")
                
                data = response.json()
                records = data.get("records", [])
                
                prices = []
                for r in records:
                    prices.append(MarketPrice(
                        state=r.get("state", "Unknown"),
                        district=r.get("district", "Unknown"),
                        market=r.get("market", "Unknown"),
                        commodity=r.get("commodity", "Unknown"),
                        variety=r.get("variety", "Unknown"),
                        grade=r.get("grade", "Unknown"),
                        arrivalDate=r.get("arrival_date", "Unknown"),
                        minPrice=float(r.get("min_price", 0)),
                        maxPrice=float(r.get("max_price", 0)),
                        modalPrice=float(r.get("modal_price", 0)),
                        unit="₹/Quintal"
                    ))
                return prices
        except httpx.RequestError as e:
            logger.error(f"Network error fetching from AGMARKNET: {e}")
            raise HTTPException(status_code=502, detail="Market information is temporarily unavailable.")
            
market_service = MarketService()
