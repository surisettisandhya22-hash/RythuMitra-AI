from pydantic import BaseModel, Field
from typing import Optional, List

class WeatherForecast(BaseModel):
    date: str = Field(..., description="The date of the forecast")
    minTemperature: float = Field(..., description="Minimum temperature")
    maxTemperature: float = Field(..., description="Maximum temperature")
    condition: str = Field(..., description="Weather condition description")
    precipitation: float = Field(..., description="Expected precipitation sum in mm")

class WeatherResponse(BaseModel):
    location: str = Field(..., description="Location name")
    temperature: float = Field(..., description="Current temperature")
    feelsLike: Optional[float] = Field(None, description="Apparent temperature")
    condition: str = Field(..., description="Weather condition description")
    humidity: float = Field(..., description="Relative humidity percentage")
    windSpeed: float = Field(..., description="Wind speed")
    rain: float = Field(..., description="Current precipitation")
    timestamp: str = Field(..., description="Time of data retrieval")
    forecast: List[WeatherForecast] = Field(default_factory=list, description="Daily forecast data")
