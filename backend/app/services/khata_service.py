from typing import List, Dict, Any
from app.schemas.khata_schema import FarmTransactionItem, FarmKhataSummary
from datetime import date

# In-memory realistic initial ledger data for Indian farmers
DEFAULT_TRANSACTIONS: List[Dict[str, Any]] = [
    {
        "id": "tx_1",
        "type": "expense",
        "category": "seeds",
        "amount": 2800.0,
        "description": "Certified Hybrid Paddy / Chilli Seeds (2 bags)",
        "date": str(date.today()),
        "crop_name": "Paddy"
    },
    {
        "id": "tx_2",
        "type": "expense",
        "category": "machinery_diesel",
        "amount": 3500.0,
        "description": "Tractor Puddling & Rotavator field preparation (3.5 hrs)",
        "date": str(date.today()),
        "crop_name": "Paddy"
    },
    {
        "id": "tx_3",
        "type": "expense",
        "category": "fertilizer",
        "amount": 4200.0,
        "description": "DAP (2 bags) + MOP Potash (1 bag) + Urea (1 bag)",
        "date": str(date.today()),
        "crop_name": "Paddy"
    },
    {
        "id": "tx_4",
        "type": "expense",
        "category": "labor_coolie",
        "amount": 5400.0,
        "description": "Transplanting labor (6 workers x ₹900)",
        "date": str(date.today()),
        "crop_name": "Paddy"
    },
    {
        "id": "tx_5",
        "type": "income",
        "category": "crop_sale",
        "amount": 38500.0,
        "description": "Early harvest vegetable & produce sale at local Mandi",
        "date": str(date.today()),
        "crop_name": "Paddy"
    }
]

class KhataService:
    _transactions: List[Dict[str, Any]] = list(DEFAULT_TRANSACTIONS)

    @classmethod
    def get_summary(cls) -> FarmKhataSummary:
        total_income = 0.0
        total_expense = 0.0
        breakdown: Dict[str, float] = {}

        for tx in cls._transactions:
            amt = float(tx.get("amount", 0.0))
            cat = tx.get("category", "other")
            if tx.get("type") == "income":
                total_income += amt
            else:
                total_expense += amt
                breakdown[cat] = breakdown.get(cat, 0.0) + amt

        net = total_income - total_expense
        is_profit = net >= 0

        insights = [
            f"Your total seasonal expenditure is ₹{total_expense:,.0f} with an income of ₹{total_income:,.0f}.",
            f"Your current Net Position is {'PROFIT' if is_profit else 'INVESTMENT'} of ₹{abs(net):,.0f}.",
            "Labor and Fertilizers make up the largest share of your production cost. Consider soil testing to optimize fertilizer dosage by up to 20%."
        ]

        items = [FarmTransactionItem(**t) for t in cls._transactions]

        return FarmKhataSummary(
            total_income=total_income,
            total_expense=total_expense,
            net_profit_loss=net,
            is_profit=is_profit,
            transactions=items,
            category_breakdown=breakdown,
            insights=insights
        )

    @classmethod
    def add_transaction(cls, item: FarmTransactionItem) -> FarmKhataSummary:
        cls._transactions.insert(0, item.dict())
        return cls.get_summary()

    @classmethod
    def delete_transaction(cls, tx_id: str) -> FarmKhataSummary:
        cls._transactions = [t for t in cls._transactions if t.get("id") != tx_id]
        return cls.get_summary()
