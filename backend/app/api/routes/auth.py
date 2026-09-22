from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import random
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from twilio.rest import Client
from app.core.config import settings

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
    
    is_email = "@" in contact
    
    try:
        if is_email:
            if settings.SMTP_SERVER and settings.SMTP_USERNAME and settings.SMTP_PASSWORD:
                # Send real email
                msg = MIMEMultipart()
                msg['From'] = settings.SMTP_USERNAME
                msg['To'] = contact
                msg['Subject'] = "Your RythuMitra AI Verification Code"
                
                body = f"Your one-time password (OTP) is: {otp_code}\n\nDo not share this code with anyone."
                msg.attach(MIMEText(body, 'plain'))
                
                server = smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT)
                server.starttls()
                server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
                server.send_message(msg)
                server.quit()
                print(f"Real email sent to {contact}")
            else:
                # Fallback to mock
                print(f"\n[MOCK EMAIL] To: {contact} | OTP: {otp_code}\n")
        else:
            if settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN and settings.TWILIO_PHONE_NUMBER:
                # Send real SMS
                client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
                message = client.messages.create(
                    body=f"Your RythuMitra AI verification code is: {otp_code}",
                    from_=settings.TWILIO_PHONE_NUMBER,
                    to=contact
                )
                print(f"Real SMS sent to {contact}, SID: {message.sid}")
            else:
                # Fallback to mock
                print(f"\n[MOCK SMS] To: {contact} | OTP: {otp_code}\n")
    except Exception as e:
        logger.error(f"Error sending OTP to {contact}: {e}")
        # Even if sending fails, we fallback to mock so the user can test locally
        print(f"\n[MOCK FALLBACK] To: {contact} | OTP: {otp_code} | Error: {e}\n")
    
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
