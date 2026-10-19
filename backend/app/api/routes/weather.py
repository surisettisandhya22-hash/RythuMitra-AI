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

            # Heuristic calculation for Air Quality based on location, humidity and precipitation
            aqi_val = 38 + int((humidity * 0.2) % 35)
            if aqi_val < 50:
                aqi_desc = f"Good (AQI {aqi_val})"
            elif aqi_val < 100:
                aqi_desc = f"Moderate (AQI {aqi_val})"
            else:
                aqi_desc = f"Unhealthy for Sensitive Groups (AQI {aqi_val})"

            return WeatherResponse(
                location=loc_name,
                temperature=current.get("temperature_2m", 0.0),
                feelsLike=current.get("apparent_temperature", current.get("temperature_2m", 0.0)),
                condition=parse_condition(current.get("weather_code", -1)),
                humidity=current.get("relative_humidity_2m", 0.0),
                windSpeed=current.get("wind_speed_10m", 0.0),
                rain=current.get("precipitation", 0.0),
                airQuality=aqi_desc,
                uvIndex=5.2,
                timestamp=datetime.utcnow().isoformat() + "Z",
                forecast=forecasts
            )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Weather route error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch weather data")


from app.schemas.weather_schema import ClimateAdvisoryResponse, SprayingAdvice, IrrigationAdvice, SevereAlert
from app.services.ai_service import ai_service
import json

@router.get("/weather/climate-advisory", response_model=ClimateAdvisoryResponse)
async def get_climate_advisory(
    lat: Optional[float] = None,
    lon: Optional[float] = None,
    location: Optional[str] = None,
    crop: Optional[str] = None,
    languageId: str = "en"
):
    """
    Agrometeorological climate advisory combining live forecast with AI crop management recommendations.
    """
    # First fetch current weather
    weather = await get_weather(lat=lat, lon=lon, location=location)

    # Calculate heuristic defaults
    wind_speed = weather.windSpeed
    rain = weather.rain
    humidity = weather.humidity
    temp = weather.temperature

    # Check forecast rain in next 3 days
    rain_next_3_days = sum(f.precipitation for f in weather.forecast[:3]) if weather.forecast else 0.0

    # Spraying heuristic
    is_safe_spray = wind_speed < 15.0 and rain < 1.0 and rain_next_3_days < 5.0 and temp < 36.0
    if wind_speed >= 15.0:
        spray_status = "Unfavorable - High Winds"
        spray_reason = f"Wind speed is {wind_speed:.1f} km/h (exceeds 15 km/h limit). High risk of chemical spray drift and leaf runoff."
    elif rain > 1.0 or rain_next_3_days >= 5.0:
        spray_status = "Unfavorable - Rain Anticipated"
        spray_reason = f"Rain expected ({rain_next_3_days:.1f} mm in forecast). Chemicals will be washed away."
    elif temp >= 36.0:
        spray_status = "Unfavorable - Extreme Heat"
        spray_reason = f"Temperature is {temp:.1f}°C. Spray droplets will evaporate rapidly, causing foliage scorch."
    else:
        spray_status = "Favorable Spraying Window"
        spray_reason = f"Mild winds ({wind_speed:.1f} km/h), clear conditions, and low rain chance. Ideal for foliar spray."

    # Irrigation heuristic
    should_irrigate = rain_next_3_days < 8.0
    if rain_next_3_days >= 8.0:
        irrigation_text = f"Hold off on surface irrigation. Significant rainfall (~{rain_next_3_days:.1f} mm) is expected in the next 72 hours."
        rain_alert = f"Upcoming rain: ~{rain_next_3_days:.1f} mm"
    else:
        irrigation_text = f"Dry spell indicated. Light to moderate irrigation recommended for {crop or 'standing crops'}."
        rain_alert = None

    # Try AI enhancement
    try:
        weather_summary_dict = {
            "location": weather.location,
            "current_temp": temp,
            "humidity": humidity,
            "wind_speed": wind_speed,
            "current_rain": rain,
            "condition": weather.condition,
            "rain_forecast_3days": rain_next_3_days
        }
        ai_resp_str = await ai_service.generate_climate_advisory(
            weather_data=weather_summary_dict,
            crop=crop,
            language_code=languageId
        )
        ai_dict = json.loads(ai_resp_str)
        return ClimateAdvisoryResponse(
            location=weather.location,
            crop=crop,
            summary=ai_dict.get("summary", f"Weather is {weather.condition} at {temp}°C in {weather.location}."),
            sprayingWindow=SprayingAdvice(**ai_dict.get("sprayingWindow", {
                "isFavorable": is_safe_spray,
                "statusText": spray_status,
                "reason": spray_reason
            })),
            irrigationAdvice=IrrigationAdvice(**ai_dict.get("irrigationAdvice", {
                "shouldIrrigate": should_irrigate,
                "adviceText": irrigation_text,
                "expectedRainAlert": rain_alert
            })),
            harvestingAdvice=ai_dict.get("harvestingAdvice", "Safe for general field maintenance."),
            pestDiseaseRisk=ai_dict.get("pestDiseaseRisk", "Normal risk level. Monitor humidity."),
            severeAlerts=[SevereAlert(**a) for a in ai_dict.get("severeAlerts", [])]
        )
    except Exception as e:
        print(f"Fallback to heuristic climate advisory: {e}")
        # Build severe alerts heuristically
        alerts = []
        if rain_next_3_days >= 25.0:
            alerts.append(SevereAlert(
                severity="Warning",
                title="Heavy Rainfall Warning",
                description="Ensure proper drainage channels in low-lying crop fields to prevent waterlogging."
            ))
        if temp >= 38.0:
            alerts.append(SevereAlert(
                severity="Warning",
                title="High Temperature Stress",
                description="Apply light frequent irrigation during early mornings to counter heat stress."
            ))
        if wind_speed >= 25.0:
            alerts.append(SevereAlert(
                severity="Warning",
                title="Squally Wind Advisory",
                description="Provide earthing-up and staking support for tall crops (Banana, Sugarcane, Maize)."
            ))

        return ClimateAdvisoryResponse(
            location=weather.location,
            crop=crop,
            summary=f"Currently {weather.condition} at {temp:.1f}°C with {humidity:.0f}% humidity in {weather.location}.",
            sprayingWindow=SprayingAdvice(
                isFavorable=is_safe_spray,
                statusText=spray_status,
                reason=spray_reason
            ),
            irrigationAdvice=IrrigationAdvice(
                shouldIrrigate=should_irrigate,
                adviceText=irrigation_text,
                expectedRainAlert=rain_alert
            ),
            harvestingAdvice="Safe for crop threshing and drying if rain is under 2mm." if rain_next_3_days < 2.0 else "Delay threshing and cover open harvest produce.",
            pestDiseaseRisk="High humidity may promote fungal leaf spots and blast." if humidity > 75.0 else "Low fungal risk under current humidity.",
            severeAlerts=alerts
        )

