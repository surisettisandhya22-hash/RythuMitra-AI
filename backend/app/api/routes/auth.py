from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
import random
import logging
import smtplib
import time
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from twilio.rest import Client
import jwt
import os
from typing import Optional
from app.core.config import settings

router = APIRouter()
logger = logging.getLogger(__name__)

# Mock JWT Secret - In production, this should come from env variables
JWT_SECRET = os.environ.get("JWT_SECRET", "super-secret-key-rythumitra")
JWT_ALGORITHM = "HS256"

# In-memory storage for OTPs. 
# Structure: { "contact": {"otp": "123456", "expires_at": 169000000, "attempts": 0, "last_requested_at": 168900000} }
_otp_store = {}

# Constants
OTP_EXPIRY_SECONDS = 300 # 5 minutes
OTP_COOLDOWN_SECONDS = 45 # 45 seconds between requests
MAX_ATTEMPTS = 3

class RequestEmailOtp(BaseModel):
    email: str

class VerifyEmailOtp(BaseModel):
    email: str
    otp: str

class RequestPhoneOtp(BaseModel):
    phone: str

class VerifyPhoneOtp(BaseModel):
    phone: str
    otp: str

def _generate_otp():
    return f"{random.randint(100000, 999999)}"

def _check_rate_limit(contact: str):
    now = time.time()
    record = _otp_store.get(contact)
    if record:
        if now - record.get("last_requested_at", 0) < OTP_COOLDOWN_SECONDS:
            raise HTTPException(status_code=429, detail="Please wait before requesting a new OTP.")

def _store_otp(contact: str, otp_code: str):
    _otp_store[contact] = {
        "otp": otp_code,
        "expires_at": time.time() + OTP_EXPIRY_SECONDS,
        "attempts": 0,
        "last_requested_at": time.time()
    }

def _verify_and_cleanup_otp(contact: str, otp_code: str):
    record = _otp_store.get(contact)
    
    if not record:
        raise HTTPException(status_code=400, detail="Invalid OTP. Please try again.")
        
    now = time.time()
    
    if now > record["expires_at"]:
        del _otp_store[contact]
        raise HTTPException(status_code=400, detail="OTP expired. Please request a new OTP.")
        
    if record["attempts"] >= MAX_ATTEMPTS:
        del _otp_store[contact]
        raise HTTPException(status_code=400, detail="Too many failed attempts. Please request a new OTP.")
        
    if record["otp"] != otp_code:
        record["attempts"] += 1
        raise HTTPException(status_code=400, detail="Incorrect OTP. Please try again.")
        
    # Success, cleanup
    del _otp_store[contact]
    
    # Generate JWT Session
    payload = {
        "sub": contact,
        "exp": time.time() + (30 * 24 * 3600) # 30 days
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token

@router.post("/request-email-otp")
async def request_email_otp(request: RequestEmailOtp):
    contact = request.email.strip().lower()
    if not contact or "@" not in contact:
        raise HTTPException(status_code=400, detail="Valid email is required")
        
    _check_rate_limit(contact)
    otp_code = _generate_otp()
    _store_otp(contact, otp_code)
    
    try:
        if settings.SMTP_SERVER and settings.SMTP_USERNAME and settings.SMTP_PASSWORD:
            msg = MIMEMultipart()
            msg['From'] = settings.SMTP_USERNAME
            msg['To'] = contact
            msg['Subject'] = "Your RythuMitra AI Verification Code"
            body = f"Your one-time password (OTP) for RythuMitra AI login is: {otp_code}\n\nThis code will expire in 5 minutes. Do not share this code with anyone."
            msg.attach(MIMEText(body, 'plain'))
            
            server = smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT)
            server.starttls()
            server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            server.send_message(msg)
            server.quit()
        else:
            logger.warning(f"SMTP not configured. Mock Email to {contact}: {otp_code}")
    except Exception as e:
        logger.error(f"Error sending email OTP: {e}")
        # Return generic success to avoid leaking internal error info
    
    return {"success": True, "message": "OTP sent successfully"}

@router.post("/verify-email-otp")
async def verify_email_otp(request: VerifyEmailOtp):
    token = _verify_and_cleanup_otp(request.email.strip().lower(), request.otp.strip())
    return {"success": True, "token": token, "message": "Login successful"}

@router.post("/request-phone-otp")
async def request_phone_otp(request: RequestPhoneOtp):
    contact = request.phone.strip()
    if not contact:
        raise HTTPException(status_code=400, detail="Phone number is required")
        
    _check_rate_limit(contact)
    otp_code = _generate_otp()
    _store_otp(contact, otp_code)
    
    try:
        if settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN and settings.TWILIO_PHONE_NUMBER:
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            client.messages.create(
                body=f"Your RythuMitra AI login code is: {otp_code}. Valid for 5 minutes.",
                from_=settings.TWILIO_PHONE_NUMBER,
                to=contact
            )
        else:
            logger.warning(f"Twilio not configured. Mock SMS to {contact}: {otp_code}")
    except Exception as e:
        logger.error(f"Error sending SMS OTP: {e}")
    
    return {"success": True, "message": "OTP sent successfully"}

@router.post("/verify-phone-otp")
async def verify_phone_otp(request: VerifyPhoneOtp):
    token = _verify_and_cleanup_otp(request.phone.strip(), request.otp.strip())
    return {"success": True, "token": token, "message": "Login successful"}

# Kept for backward compatibility with mobile app while we transition
@router.post("/send-otp")
async def send_otp_legacy(request: RequestPhoneOtp): # Reusing model shape (just a contact string)
    contact = request.phone.strip()
    if "@" in contact:
        return await request_email_otp(RequestEmailOtp(email=contact))
    return await request_phone_otp(RequestPhoneOtp(phone=contact))

@router.post("/verify-otp")
async def verify_otp_legacy(request: VerifyPhoneOtp):
    contact = request.phone.strip()
    if "@" in contact:
        return await verify_email_otp(VerifyEmailOtp(email=contact, otp=request.otp))
    return await verify_phone_otp(VerifyPhoneOtp(phone=contact, otp=request.otp))
