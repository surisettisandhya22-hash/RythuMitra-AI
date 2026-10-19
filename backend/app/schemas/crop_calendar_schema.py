from pydantic import BaseModel
from typing import List, Optional

class CropStageTask(BaseModel):
    id: str
    day_offset: int
    title: str
    description: str
    category: str  # 'fertilizer', 'irrigation', 'pest_control', 'field_care'
    priority: str  # 'high', 'medium', 'low'
    completed: bool = False

class CropGrowthStage(BaseModel):
    stage_name: str
    stage_key: str
    day_range: str
    icon: str
    summary: str
    tasks: List[CropStageTask]

class CropCalendarResponse(BaseModel):
    crop_name: str
    crop_variety: Optional[str] = "Standard Hybrid"
    sowing_date: str
    total_duration_days: int
    current_day: int
    current_stage: str
    stages: List[CropGrowthStage]
    smart_tips: List[str]
