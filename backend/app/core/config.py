from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_ENV: str = "development"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Existing settings from .env
    GEMINI_API_KEY: str = ""
    DATA_GOV_API_KEY: str = ""
    WEATHER_API_KEY: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'

settings = Settings()
