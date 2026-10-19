from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import json
from app.services.ai_service import ai_service
from app.services.fertilizer_service import fertilizer_service
from app.schemas.fertilizer_schema import FertilizerCalculationRequest

router = APIRouter()

class FertilizerRequest(BaseModel):
    crop: str
    area: float
    unit: str

@router.post("/calculate_fertilizer")
async def get_fertilizer_calculation(req: FertilizerRequest):
    # Try AI calculation first if available
    try:
        result = await ai_service.calculate_fertilizer(req.crop, req.area, req.unit)
        data = json.loads(result)
        return data
    except Exception as e:
        # Fallback to high-precision ICAR scientific agronomic engine
        try:
            calc_req = FertilizerCalculationRequest(
                crop=req.crop,
                area=req.area,
                unit=req.unit,
                farmingType="Integrated",
                languageId="en"
            )
            plan = fertilizer_service.calculate_fertilizer_plan(calc_req)
            mop_str = "0 kg"
            tsp_str = "0 kg"
            urea_str = "0 kg"
            for item in plan.primaryFertilizers:
                if "Urea" in item.name:
                    urea_str = f"{item.quantityKg} kg / {item.bagsCount} bags"
                elif "MOP" in item.name or "Potash" in item.name:
                    mop_str = f"{item.quantityKg} kg / {item.bagsCount} bags"
                elif "DAP" in item.name or "SSP" in item.name:
                    tsp_str = f"{item.quantityKg} kg / {item.bagsCount} bags"

            return {
                "mop": mop_str,
                "tsp": tsp_str,
                "urea": urea_str
            }
        except Exception as inner_e:
            raise HTTPException(status_code=500, detail=str(inner_e))

