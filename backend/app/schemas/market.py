from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class MarketPrice(BaseModel):
    state: str
    district: str
    market: str
    commodity: str
    variety: str
    grade: str
    arrivalDate: str
    minPrice: float
    maxPrice: float
    modalPrice: float
    unit: str = "₹/Quintal"

class MarketResponse(BaseModel):
    data: List[MarketPrice]
    status: str
    message: str
