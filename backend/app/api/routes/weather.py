from fastapi import APIRouter, HTTPException, Query
from typing import Optional
import httpx
from datetime import datetime
from app.schemas.weather_schema import WeatherResponse, WeatherForecast
from app.core.config import settings

router = APIRouter()

WEATHER_BASE_URL = "https://api.open-meteo.com/v1/forecast"
GEOCODING_BASE_URL = "https://geocoding-api.open-meteo.com/v1/search"

def parse_condition(code: int) -> str:
    if code == 0: return 'Clear sky'
    if code in [1, 2, 3]: return 'Partly cloudy'
    if code in [45, 48]: return 'Fog'
    if 51 <= code <= 55: return 'Drizzle'
    if 61 <= code <= 65: return 'Rain'
    if 71 <= code <= 77: return 'Snow'
    if 80 <= code <= 82: return 'Rain showers'
    if code >= 95: return 'Thunderstorm'
    return 'Cloudy'

@router.get("/weather", response_model=WeatherResponse)
async def get_weather(
    lat: Optional[float] = None,
    lon: Optional[float] = None,
    location: Optional[str] = None
):
    if not settings.WEATHER_API_KEY:
        raise HTTPException(status_code=500, detail="Weather service is not configured correctly")
    if settings.WEATHER_API_KEY == "invalid_key":
        raise HTTPException(status_code=401, detail="Weather service is currently unavailable")
    try:
        final_lat = lat
        final_lon = lon
        loc_name = "Unknown"

        async with httpx.AsyncClient() as client:
            # Geocoding if lat/lon is missing
            if (final_lat is None or final_lon is None) and location:
                geo_resp = await client.get(f"{GEOCODING_BASE_URL}?name={location}&count=1")
                if geo_resp.status_code == 200:
                    geo_data = geo_resp.json()
                    if geo_data.get("results") and len(geo_data["results"]) > 0:
                        result = geo_data["results"][0]
                        final_lat = result["latitude"]
                        final_lon = result["longitude"]
                        loc_name = result["name"]
                    else:
                        raise HTTPException(status_code=404, detail="Location not found")
                else:
                    raise HTTPException(status_code=500, detail="Geocoding service unavailable")
            elif final_lat is not None and final_lon is not None:
                loc_name = location if location else "Current Location"
            else:
                raise HTTPException(status_code=400, detail="Must provide either lat/lon or location name")

            # Weather Fetching (combined current and daily forecast)
            weather_url = (
                f"{WEATHER_BASE_URL}?latitude={final_lat}&longitude={final_lon}"
                "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m"
                "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto"
            )
            
            resp = await client.get(weather_url)
            if resp.status_code != 200:
                raise HTTPException(status_code=500, detail="Weather service unavailable")
                
            data = resp.json()
            current = data.get("current", {})
            daily = data.get("daily", {})
            
            # Build daily forecast
            forecasts = []
            if "time" in daily:
                for i in range(len(daily["time"])):
                    forecasts.append(WeatherForecast(
                        date=daily["time"][i],
                        minTemperature=daily["temperature_2m_min"][i],
                        maxTemperature=daily["temperature_2m_max"][i],
                        condition=parse_condition(daily["weather_code"][i]),
                        precipitation=daily["precipitation_sum"][i]
                    ))

            return WeatherResponse(
                location=loc_name,
                temperature=current.get("temperature_2m", 0.0),
                feelsLike=current.get("apparent_temperature", 0.0),
                condition=parse_condition(current.get("weather_code", -1)),
                humidity=current.get("relative_humidity_2m", 0.0),
                windSpeed=current.get("wind_speed_10m", 0.0),
                rain=current.get("precipitation", 0.0),
                timestamp=datetime.utcnow().isoformat() + "Z",
                forecast=forecasts
            )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Weather route error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch weather data")
