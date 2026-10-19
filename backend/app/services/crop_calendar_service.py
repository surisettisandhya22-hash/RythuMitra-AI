from datetime import datetime, date
from typing import List, Dict, Any
from app.schemas.crop_calendar_schema import CropCalendarResponse, CropGrowthStage, CropStageTask

# Curated crop calendars based on ICAR & State Agricultural Universities standards
CROP_KNOWLEDGE_BASE: Dict[str, Dict[str, Any]] = {
    "paddy": {
        "duration": 135,
        "stages": [
            {
                "stage_name": "Nursery & Seedling Stage (నారుమడి దశ)",
                "stage_key": "nursery",
                "day_range": "Day 0 - 25",
                "icon": "🌱",
                "summary": "Seed treatment with Carbendazim, nursery bed watering, and stem borer monitoring.",
                "tasks": [
                    {"id": "pad_1", "day_offset": 1, "title": "Seed Treatment (విత్తన శుద్ధి)", "description": "Treat seeds with Carbendazim 2g/kg or Trichoderma viride 10g/kg to prevent seed-borne diseases.", "category": "field_care", "priority": "high"},
                    {"id": "pad_2", "day_offset": 10, "title": "Nursery Top Dressing", "description": "Apply Urea 1kg per 100 sq.m nursery area for vigorous root and shoot growth.", "category": "fertilizer", "priority": "medium"},
                    {"id": "pad_3", "day_offset": 22, "title": "Pre-Transplant Spray", "description": "Spray Chlorpyriphos 2ml/L to protect young seedlings from Gall Midge and Stem Borer before uprooting.", "category": "pest_control", "priority": "high"}
                ]
            },
            {
                "stage_name": "Tillering & Vegetative Stage (పిలకల దశ)",
                "stage_key": "tillering",
                "day_range": "Day 25 - 55",
                "icon": "🌾",
                "summary": "Main field transplanting, water shallow submergence (2-3 cm), and basal NPK application.",
                "tasks": [
                    {"id": "pad_4", "day_offset": 25, "title": "Basal Fertilizer Application", "description": "Apply full dose of SSP (Phosphorus) and MOP (Potash) along with 1/3rd dose of Nitrogen during final puddling.", "category": "fertilizer", "priority": "high"},
                    {"id": "pad_5", "day_offset": 40, "title": "First Top Dressing (Urea & Zinc)", "description": "Broadcast Urea 25-30kg/acre along with Zinc Sulphate 10kg/acre if deficiency symptoms appear.", "category": "fertilizer", "priority": "high"},
                    {"id": "pad_6", "day_offset": 48, "title": "Leaf Folder & Brown Planthopper Inspection", "description": "Check lower stem for BPH nymphs and leaf folds; maintain water drainage to break pest cycles.", "category": "pest_control", "priority": "medium"}
                ]
            },
            {
                "stage_name": "Panicle Initiation & Booting (చిరుపొట్ట దశ)",
                "stage_key": "booting",
                "day_range": "Day 55 - 85",
                "icon": "🌿",
                "summary": "Critical water requirement phase; apply second top dressing and watch for blast disease.",
                "tasks": [
                    {"id": "pad_7", "day_offset": 60, "title": "Second Nitrogen Top Dressing", "description": "Apply remaining 1/3rd dose of Urea + 10kg MOP per acre to enhance panicle grain count.", "category": "fertilizer", "priority": "high"},
                    {"id": "pad_8", "day_offset": 70, "title": "Water Level Maintenance", "description": "Ensure continuous standing water of 5 cm in the field. Avoid moisture stress at all costs.", "category": "irrigation", "priority": "high"},
                    {"id": "pad_9", "day_offset": 80, "title": "Sheath Blight & Neck Blast Vigil", "description": "Spray Hexaconazole or Azoxystrobin 1ml/L if rust-like lesions are visible on leaf sheaths.", "category": "pest_control", "priority": "medium"}
                ]
            },
            {
                "stage_name": "Grain Filling & Maturity (గింజ పాలుపోసుకునే & కోత దశ)",
                "stage_key": "maturity",
                "day_range": "Day 85 - 135",
                "icon": "🚜",
                "summary": "Grain milk to dough stage; drain field 10 days before harvesting.",
                "tasks": [
                    {"id": "pad_10", "day_offset": 95, "title": "Foliar 13:0:45 Potassium Nitrate Spray", "description": "Spray 1% KNO3 (10g/L) for bold, shiny, heavy grains and high milling percentage.", "category": "fertilizer", "priority": "medium"},
                    {"id": "pad_11", "day_offset": 120, "title": "Field Drainage Before Harvest", "description": "Completely drain out standing water 10-12 days before anticipated harvest for uniform ripening.", "category": "irrigation", "priority": "high"},
                    {"id": "pad_12", "day_offset": 135, "title": "Harvesting at 18-20% Moisture", "description": "Harvest when 85% of grains in panicles turn golden yellow. Dry under shade to 14% moisture before storage.", "category": "field_care", "priority": "high"}
                ]
            }
        ],
        "tips": [
            "Maintain alternate wetting and drying (AWD) during vegetative phase to save 25% water and boost root aeration.",
            "Never apply excessive nitrogen late in the season to prevent blast disease.",
            "Install yellow sticky traps (10/acre) to control sucking pests organically."
        ]
    },
    "chilli": {
        "duration": 150,
        "stages": [
            {
                "stage_name": "Nursery & Early Vegetative (మొక్క నాటు & ఎదుగుదల దశ)",
                "stage_key": "vegetative",
                "day_range": "Day 0 - 35",
                "icon": "🌱",
                "summary": "Pro-tray nursery or raised beds, transplanting in ridges & furrows with drip irrigation.",
                "tasks": [
                    {"id": "chi_1", "day_offset": 1, "title": "Seed / Drench Treatment", "description": "Drench nursery seedlings with Trichoderma viride or Carbendazim 1g/L against damping-off disease.", "category": "field_care", "priority": "high"},
                    {"id": "chi_2", "day_offset": 15, "title": "Basal Compost & NPK Incorporation", "description": "Incorporate 10 tonnes Well-decomposed FYM + 50kg DAP + 30kg MOP per acre before bed formation.", "category": "fertilizer", "priority": "high"},
                    {"id": "chi_3", "day_offset": 30, "title": "Thrips & Mites Early Inspection", "description": "Inspect leaf underside for curling (Gemini virus vector). Install 15 blue sticky traps per acre for thrips.", "category": "pest_control", "priority": "high"}
                ]
            },
            {
                "stage_name": "Branching & Flowering (కొమ్మలు & పూత దశ)",
                "stage_key": "flowering",
                "day_range": "Day 35 - 75",
                "icon": "🌸",
                "summary": "Side shoot development, active flower blooming, and flower drop management.",
                "tasks": [
                    {"id": "chi_4", "day_offset": 45, "title": "Flower Booster Micronutrient Spray", "description": "Foliar spray of Planofix (NAA) @ 4ml per 15L water or Boron 1g/L to prevent premature blossom drop.", "category": "fertilizer", "priority": "high"},
                    {"id": "chi_5", "day_offset": 55, "title": "Black Thrips & Aphids Control", "description": "Spray Spinetoram 11.7% SC (0.9ml/L) or Neem oil 10,000 ppm (2ml/L) during early morning hours.", "category": "pest_control", "priority": "high"},
                    {"id": "chi_6", "day_offset": 68, "title": "Controlled Fertigation", "description": "Supply 19:19:19 water soluble fertilizer 3kg/acre via drip irrigation every 5 days.", "category": "irrigation", "priority": "medium"}
                ]
            },
            {
                "stage_name": "Fruit Formation & Green Picking (కాయలు & పచ్చిమిర్చి కోత)",
                "stage_key": "fruiting",
                "day_range": "Day 75 - 110",
                "icon": "🌶️",
                "summary": "Rapid green pod elongation and multiple pickings for fresh market.",
                "tasks": [
                    {"id": "chi_7", "day_offset": 80, "title": "Calcium Nitrate + Boron Spray", "description": "Apply 13:0:45 (5g/L) + Calcium Nitrate (3g/L) to prevent blossom-end rot and produce firm pods.", "category": "fertilizer", "priority": "high"},
                    {"id": "chi_8", "day_offset": 90, "title": "Anthracnose (Die-back) Shield", "description": "Spray Azoxystrobin + Difenoconazole (1ml/L) to prevent black spots on fruit.", "category": "pest_control", "priority": "medium"},
                    {"id": "chi_9", "day_offset": 105, "title": "First Green Chilli Picking", "description": "Harvest mature green chillies carefully without damaging side branches; pick every 8-10 days.", "category": "field_care", "priority": "medium"}
                ]
            },
            {
                "stage_name": "Ripening & Red Dry Chilli Harvest (ఎరుపు రంగు & ఎండుమిర్చి కోత)",
                "stage_key": "red_maturity",
                "day_range": "Day 110 - 150",
                "icon": "🔥",
                "summary": "Turn to deep bright red, solar drying on clean tarpaulin sheets.",
                "tasks": [
                    {"id": "chi_10", "day_offset": 125, "title": "Red Pod Color Enhancement", "description": "Spray 0:0:50 (Potassium Sulphate) 5g/L to enhance deep capsaicin red pigmentation.", "category": "fertilizer", "priority": "medium"},
                    {"id": "chi_11", "day_offset": 140, "title": "Red Ripe Picking", "description": "Harvest completely red ripe pods with intact stalk; avoid picking damaged or spotted fruits.", "category": "field_care", "priority": "high"},
                    {"id": "chi_12", "day_offset": 148, "title": "Solar Tarpaulin Drying", "description": "Dry on clean food-grade polythene sheets under sunlight for 10-14 days until moisture drops below 10%.", "category": "field_care", "priority": "high"}
                ]
            }
        ],
        "tips": [
            "Use blue sticky traps for thrips and yellow traps for whiteflies & aphids.",
            "Avoid flooding soil; Chilli roots are sensitive to waterlogging and die-back.",
            "Mulching with silver-black polythene film suppresses 90% weeds and conserves moisture."
        ]
    },
    "cotton": {
        "duration": 160,
        "stages": [
            {
                "stage_name": "Sowing & Square Formation (విత్తనం & మొగ్గ దశ)",
                "stage_key": "vegetative",
                "day_range": "Day 0 - 45",
                "icon": "🌱",
                "summary": "Dibbling with optimum soil moisture, thinning to single seedling per hill, and early weed control.",
                "tasks": [
                    {"id": "cot_1", "day_offset": 1, "title": "Sowing with Trichoderma & Imidacloprid", "description": "Ensure seed is treated with Imidacloprid 70WS (5g/kg) to shield against sucking pests for 30 days.", "category": "field_care", "priority": "high"},
                    {"id": "cot_2", "day_offset": 20, "title": "Thinning & Gap Filling", "description": "Retain one healthy vigorous seedling per hill; fill gaps to maintain 7,400 plants/acre population.", "category": "field_care", "priority": "high"},
                    {"id": "cot_3", "day_offset": 35, "title": "First Nitrogen Dose & Earthing Up", "description": "Apply 30kg Urea + 15kg MOP as side band placement 5 cm away from plant and perform earthing up.", "category": "fertilizer", "priority": "high"}
                ]
            },
            {
                "stage_name": "Flowering & Peak Boll Setting (పూత & కాయ దశ)",
                "stage_key": "boll_setting",
                "day_range": "Day 45 - 95",
                "icon": "🌸",
                "summary": "Square blooming into white/pink flowers; critical defense against Pink Bollworm.",
                "tasks": [
                    {"id": "cot_4", "day_offset": 55, "title": "Pheromone Trap Installation (PBW)", "description": "Install 8 Pherolure traps per acre to track Pink Bollworm adult moth activity.", "category": "pest_control", "priority": "high"},
                    {"id": "cot_5", "day_offset": 65, "title": "Second Nitrogen Top Dressing", "description": "Apply 30kg Urea per acre during square initiation; ensure adequate root zone moisture.", "category": "fertilizer", "priority": "high"},
                    {"id": "cot_6", "day_offset": 80, "title": "Boron & Magnesium Sulphate Spray", "description": "Foliar spray of 1% MgSO4 + 0.1% Boron (1g/L) to prevent red leaf disease and square shedding.", "category": "fertilizer", "priority": "medium"}
                ]
            },
            {
                "stage_name": "Boll Maturation & Bursting (కాయ ముదురుట & పత్తి విచ్చుకొను దశ)",
                "stage_key": "boll_bursting",
                "day_range": "Day 95 - 160",
                "icon": "☁️",
                "summary": "Fluffy white cotton locks bursting open; periodic clean picking in dry morning conditions.",
                "tasks": [
                    {"id": "cot_7", "day_offset": 105, "title": "Potassium Nitrate (13:0:45) Spray", "description": "Spray 2% KNO3 (20g/L) twice at 15-day intervals to enhance boll size and fiber strength.", "category": "fertilizer", "priority": "medium"},
                    {"id": "cot_8", "day_offset": 120, "title": "First Clean Picking", "description": "Pick only fully opened dry bolls after 10 AM to avoid dew moisture. Store in dry cotton cloth bags.", "category": "field_care", "priority": "high"},
                    {"id": "cot_9", "day_offset": 150, "title": "Final Picking & Field Residue Management", "description": "Complete 3rd picking. Shred dry stalks with rotavator to destroy overwintering Pink Bollworm larvae.", "category": "field_care", "priority": "high"}
                ]
            }
        ],
        "tips": [
            "Install Pheromone traps at 45 DAS to monitor Pink Bollworm ETL (>8 moths/trap for 3 consecutive days).",
            "Avoid high doses of nitrogen during flowering to prevent excessive vegetative leafy growth.",
            "Spray 1% Neem oil as a deterrent against early sucking pest flare-ups."
        ]
    },
    "tomato": {
        "duration": 120,
        "stages": [
            {
                "stage_name": "Transplanting & Staking (మొక్క నాటు & స్టేకింగ్ దశ)",
                "stage_key": "vegetative",
                "day_range": "Day 0 - 30",
                "icon": "🌱",
                "summary": "Bed preparation, drip laying, transplanting 25-day seedlings and bamboo/wire staking.",
                "tasks": [
                    {"id": "tom_1", "day_offset": 1, "title": "Transplanting & Root Dip", "description": "Dip seedling roots in Imidacloprid (0.5ml/L) + Carbendazim (1g/L) solution for 15 mins before planting.", "category": "field_care", "priority": "high"},
                    {"id": "tom_2", "day_offset": 12, "title": "Basal Starter Fertigation (19:19:19)", "description": "Inject water soluble 19:19:19 @ 2.5kg/acre through drip irrigation to stimulate rapid root spread.", "category": "fertilizer", "priority": "high"},
                    {"id": "tom_3", "day_offset": 25, "title": "Staking & Trellising", "description": "Tie plants to bamboo stakes or nylon trellis to keep fruits off the damp soil and prevent fruit rot.", "category": "field_care", "priority": "high"}
                ]
            },
            {
                "stage_name": "Flowering & Fruit Set (పూత & పిందె దశ)",
                "stage_key": "flowering",
                "day_range": "Day 30 - 65",
                "icon": "🍅",
                "summary": "Continuous yellow flowering clusters, early fruit set, and leaf curl virus management.",
                "tasks": [
                    {"id": "tom_4", "day_offset": 35, "title": "Whitefly & Leaf Miner Management", "description": "Install yellow sticky sheets. Spray Cyantraniliprole 10.26% OD (1.8ml/L) for leaf miners.", "category": "pest_control", "priority": "high"},
                    {"id": "tom_5", "day_offset": 45, "title": "Calcium + Boron Fertigation", "description": "Supply Calcium Nitrate 3kg/acre + Boron 250g/acre weekly to stop Blossom End Rot (black base).", "category": "fertilizer", "priority": "high"},
                    {"id": "tom_6", "day_offset": 58, "title": "Early Blight Preventive Spray", "description": "Spray Mancozeb 75% WP (2.5g/L) or Chlorothalonil 2g/L before morning humidity peaks.", "category": "pest_control", "priority": "medium"}
                ]
            },
            {
                "stage_name": "Fruit Bulking & Multi-Picking (కాయ పెరుగుదల & కోత దశ)",
                "stage_key": "harvesting",
                "day_range": "Day 65 - 120",
                "icon": "🧺",
                "summary": "Firm fruit turning breaker to pink-red; harvest every 4-5 days.",
                "tasks": [
                    {"id": "tom_7", "day_offset": 70, "title": "Potassium Booster (0:0:50)", "description": "Fertigate Potassium Sulphate (0:0:50) 4kg/acre for glossy uniform red color and thicker fruit skin.", "category": "fertilizer", "priority": "high"},
                    {"id": "tom_8", "day_offset": 80, "title": "Breaker Stage Harvesting", "description": "Pick tomatoes at breaker/turning stage (slight pink at blossom end) for long distance transport.", "category": "field_care", "priority": "high"},
                    {"id": "tom_9", "day_offset": 100, "title": "Grading & Plastic Crate Packing", "description": "Sort tomatoes into Grade A, B & C; pack in ventilated 25kg plastic crates to prevent crushing.", "category": "field_care", "priority": "medium"}
                ]
            }
        ],
        "tips": [
            "Always stake indeterminate tomato varieties; increases yield by 35% and prevents soil rot.",
            "Calcium deficiency causes Blossom End Rot (black sunken bottoms); apply calcium nitrate regularly.",
            "Water regularly without long dry spells to prevent fruit skin cracking."
        ]
    }
}

class CropCalendarService:
    @staticmethod
    def get_crop_calendar(crop_name: str, sowing_date_str: str) -> CropCalendarResponse:
        crop_key = crop_name.lower().strip()
        data = CROP_KNOWLEDGE_BASE.get(crop_key, CROP_KNOWLEDGE_BASE["tomato"])
        
        # Calculate current elapsed day
        try:
            sowing_date = datetime.strptime(sowing_date_str, "%Y-%m-%d").date()
        except Exception:
            sowing_date = date.today()
            
        today = date.today()
        elapsed_days = max(1, (today - sowing_date).days)
        total_duration = data["duration"]
        
        # Determine current stage
        current_stage = data["stages"][0]["stage_name"]
        for stage in data["stages"]:
            parts = stage["day_range"].replace("Day ", "").split("-")
            start = int(parts[0].strip())
            end = int(parts[1].strip())
            if start <= elapsed_days <= end:
                current_stage = stage["stage_name"]
                break
        
        stages = [CropGrowthStage(**st) for st in data["stages"]]
        
        return CropCalendarResponse(
            crop_name=crop_name.capitalize(),
            crop_variety="Hybrid High Yielding",
            sowing_date=sowing_date_str,
            total_duration_days=total_duration,
            current_day=min(elapsed_days, total_duration),
            current_stage=current_stage,
            stages=stages,
            smart_tips=data["tips"]
        )
