from pydantic import BaseModel
from typing import List, Optional
from datetime import date

class FarmTransactionItem(BaseModel):
    id: str
    type: str  # 'expense' or 'income'
    category: str  # 'seeds', 'fertilizer', 'labor_coolie', 'machinery_diesel', 'pesticides', 'crop_sale', 'subsidy', 'other'
    amount: float
    description: str
    date: str
    crop_name: Optional[str] = "General Farm"

class FarmKhataSummary(BaseModel):
    total_income: float
    total_expense: float
    net_profit_loss: float
    is_profit: bool
    transactions: List[FarmTransactionItem]
    category_breakdown: dict
    insights: List[str]
