from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import health, chat, scanner, market, weather
from app.core.config import settings

app = FastAPI(
    title="RythuMitra AI API",
    description="Backend API for RythuMitra AI",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Include routers
app.include_router(health.router, tags=["health"])
app.include_router(chat.router, prefix="/api", tags=["chat"])
app.include_router(scanner.router, prefix="/api", tags=["scanner"])
app.include_router(market.router, prefix="/api/market", tags=["market"])
app.include_router(weather.router, prefix="/api/v1", tags=["weather"])

@app.get("/")
def read_root():
    return {"message": "RythuMitra AI Backend is running"}
