from fastapi import APIRouter
from app.schemas.khata_schema import FarmTransactionItem, FarmKhataSummary
from app.services.khata_service import KhataService

router = APIRouter()

@router.get("/summary", response_model=FarmKhataSummary)
def get_khata_summary():
    """
    Get the overall farm digital ledger summary, totals, profit/loss and transactions.
    """
    return KhataService.get_summary()

@router.post("/transaction", response_model=FarmKhataSummary)
def add_transaction(item: FarmTransactionItem):
    """
    Record a new farm expense or income item.
    """
    return KhataService.add_transaction(item)

@router.delete("/transaction/{tx_id}", response_model=FarmKhataSummary)
def delete_transaction(tx_id: str):
    """
    Delete a recorded ledger entry.
    """
    return KhataService.delete_transaction(tx_id)
