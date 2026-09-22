from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_ENV: str = "development"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Existing settings from .env
    GEMINI_API_KEY: str = ""
    DATA_GOV_API_KEY: str = ""
    WEATHER_API_KEY: str = ""
    
    # Email settings
    SMTP_SERVER: str = ""
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    
    # Twilio settings
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_PHONE_NUMBER: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'

settings = Settings()
