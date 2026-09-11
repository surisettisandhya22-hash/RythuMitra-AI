from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from app.services.ai_service import ai_service
from app.schemas.scan_schema import ScanAnalysisResult
import json

router = APIRouter()

@router.post("/scan/analyze", response_model=ScanAnalysisResult)
async def analyze_crop_image_endpoint(
    image: UploadFile = File(...),
    languageId: str = Form("en"),
    cropName: str = Form(None),
    description: str = Form(None)
):
    """
    Analyzes an uploaded crop image using RythuMitra Vision AI.
    """
    try:
        # Read the file data
        image_data = await image.read()
        
        # Check size (e.g. limit to 10MB)
        if len(image_data) > 10 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Image size exceeds 10MB limit.")
            
        # Call AI service
        json_response_str = await ai_service.analyze_crop_image(
            image_data=image_data,
            language_code=languageId,
            crop_name=cropName,
            description=description
        )
        
        # Parse the JSON
        try:
            result_dict = json.loads(json_response_str)
            return ScanAnalysisResult(**result_dict)
        except Exception as json_err:
            print(f"Failed to parse JSON response: {json_response_str}")
            raise HTTPException(status_code=500, detail="AI returned an invalid analysis format.")
            
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to process image analysis request.")
