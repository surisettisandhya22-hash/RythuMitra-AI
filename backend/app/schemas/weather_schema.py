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
    airQuality: Optional[str] = Field("Good (AQI 42)", description="Air Quality index description")
    uvIndex: Optional[float] = Field(None, description="UV Index")
    timestamp: str = Field(..., description="Time of data retrieval")
    forecast: List[WeatherForecast] = Field(default_factory=list, description="Daily forecast data")

class SprayingAdvice(BaseModel):
    isFavorable: bool = Field(..., description="True if safe to spray chemicals/fertilizers")
    statusText: str = Field(..., description="Status title e.g. 'Favorable Window', 'High Rain Risk', 'High Wind Risk'")
    reason: str = Field(..., description="Explanation of why it is or is not safe")

class IrrigationAdvice(BaseModel):
    shouldIrrigate: bool = Field(..., description="True if irrigation recommended")
    adviceText: str = Field(..., description="Detailed watering recommendation")
    expectedRainAlert: Optional[str] = Field(None, description="Rainfall expected in next 48-72 hours")

class SevereAlert(BaseModel):
    severity: str = Field(..., description="Normal, Moderate, Warning, or Severe")
    title: str = Field(..., description="Alert headline")
    description: str = Field(..., description="Details and actionable protection tips")

class ClimateAdvisoryResponse(BaseModel):
    location: str = Field(..., description="Field or farm location")
    crop: Optional[str] = Field(None, description="Target crop")
    summary: str = Field(..., description="Farmer-friendly 2-line climate overview")
    sprayingWindow: SprayingAdvice
    irrigationAdvice: IrrigationAdvice
    harvestingAdvice: str = Field(..., description="Field operations & harvesting advice")
    pestDiseaseRisk: str = Field(..., description="Pest or fungal outbreak risk based on weather")
    severeAlerts: List[SevereAlert] = Field(default_factory=list)
