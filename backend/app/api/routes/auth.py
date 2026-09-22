from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import random
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

# In-memory storage for OTPs. In production, use Redis or a database.
# Structure: { "contact": "otp_code" }
_otp_store = {}

class SendOtpRequest(BaseModel):
    contact: str

class VerifyOtpRequest(BaseModel):
    contact: str
    otp: str

@router.post("/send-otp")
async def send_otp(request: SendOtpRequest):
    contact = request.contact.strip()
    if not contact:
        raise HTTPException(status_code=400, detail="Contact is required")
    
    # Generate a random 6-digit OTP
    otp_code = f"{random.randint(100000, 999999)}"
    
    # Store it
    _otp_store[contact] = otp_code
    
    # Simulate sending by printing to console
    print(f"\n=========================================")
    print(f"MOCK OTP NOTIFICATION")
    print(f"To: {contact}")
    print(f"Your RythuMitra AI verification code is: {otp_code}")
    print(f"=========================================\n")
    
    return {"success": True, "message": "OTP sent successfully"}

@router.post("/verify-otp")
async def verify_otp(request: VerifyOtpRequest):
    contact = request.contact.strip()
    otp = request.otp.strip()
    
    if not contact or not otp:
        raise HTTPException(status_code=400, detail="Contact and OTP are required")
        
    stored_otp = _otp_store.get(contact)
    
    if stored_otp and stored_otp == otp:
        # OTP verified, remove it from store to prevent reuse
        del _otp_store[contact]
        return {"success": True, "message": "OTP verified successfully"}
    else:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
