import math
from datetime import datetime, timedelta
from typing import Dict, Any, List
from app.schemas.irrigation_schema import (
    IrrigationCalculationRequest,
    IrrigationAdviceResponse,
    IrrigationScheduleItem,
    IrrigationMethodComparison,
)

CROP_WATER_DATABASE: Dict[str, Dict[str, Any]] = {
    "paddy": {
        "nameEn": "Rice / Paddy",
        "nameTe": "వరి (Paddy / Rice)",
        "kc": {
            "Initial / Seedling": 1.10,
            "Vegetative": 1.15,
            "Flowering / Critical": 1.30,
            "Maturity / Ripening": 0.90,
        },
        "criticalStagesEn": [
            "Panicle Initiation (చిరుపొట్ట దశ) - Moisture stress causes unfilled grains",
            "Flowering / Anthesis (పూత దశ) - Water depth of 2-3 cm required",
            "Grain filling / Milky stage (గింజ పాలుపోసుకునే దశ)",
        ],
        "criticalStagesTe": [
            "చిరుపొట్ట దశ (Panicle Initiation) - నీటి ఎద్దడి వస్తే తాలు గింజలు పెరుగుతాయి",
            "పూత దశ (Flowering) - 2-3 సెం.మీ నీరు నిలకడగా ఉండాలి",
            "గింజ పాలుపోసుకునే దశ (Milk stage) - పొలంలో తగినంత పదును ఉండాలి",
        ],
        "awdRecommended": True,
        "baseEt0": 5.2,
    },
    "cotton": {
        "nameEn": "Cotton",
        "nameTe": "ప్రత్తి (Cotton)",
        "kc": {
            "Initial / Seedling": 0.45,
            "Vegetative": 0.75,
            "Flowering / Critical": 1.20,
            "Maturity / Ripening": 0.65,
        },
        "criticalStagesEn": [
            "Square formation / Flowering (పూత & పిందె దశ) - Prevents flower shedding",
            "Boll development (కాయ పెరిగే దశ) - Avoid soil cracking",
        ],
        "criticalStagesTe": [
            "పూత, పిందె దశ - తేమ తగ్గితే పూత రాలిపోతుంది",
            "కాయలు పెరిగే దశ - నేల బీటలు వారకుండా సకాలంలో తడులు ఇవ్వాలి",
        ],
        "awdRecommended": False,
        "baseEt0": 5.5,
    },
    "chilli": {
        "nameEn": "Chilli",
        "nameTe": "మిరప (Chilli)",
        "kc": {
            "Initial / Seedling": 0.50,
            "Vegetative": 0.80,
            "Flowering / Critical": 1.15,
            "Maturity / Ripening": 0.75,
        },
        "criticalStagesEn": [
            "Flowering & Fruit set - Critical moisture prevents flower drop",
            "Fruit elongation & ripening",
        ],
        "criticalStagesTe": [
            "పూత & పిందె కట్టే దశ - తేమ హెచ్చుతగ్గులైతే పూత రాలిపోతుంది",
            "కాయ ఊరే దశ & కోతల మధ్య దశ",
        ],
        "awdRecommended": False,
        "baseEt0": 5.4,
    },
    "maize": {
        "nameEn": "Maize / Corn",
        "nameTe": "మొక్కజొన్న (Maize)",
        "kc": {
            "Initial / Seedling": 0.40,
            "Vegetative": 0.80,
            "Flowering / Critical": 1.20,
            "Maturity / Ripening": 0.60,
        },
        "criticalStagesEn": [
            "Tasseling & Silking (కంకి పూత & పాలుపోసుకునే దశ) - Severe moisture stress causes barren cobs",
            "Knee-high vegetative phase",
        ],
        "criticalStagesTe": [
            "కంకి పూత & సిల్కింగ్ దశ - నీరు లేకపోతే కంకిలో గింజ కట్టదు",
            "మోకాలు లోతు ఎదుగుదల దశ",
        ],
        "awdRecommended": False,
        "baseEt0": 5.0,
    },
    "groundnut": {
        "nameEn": "Groundnut / Peanut",
        "nameTe": "వేరుశనగ (Groundnut)",
        "kc": {
            "Initial / Seedling": 0.40,
            "Vegetative": 0.70,
            "Flowering / Critical": 1.05,
            "Maturity / Ripening": 0.55,
        },
        "criticalStagesEn": [
            "Flowering & Peg penetration (ఊడలు దిగే దశ) - Soil must be loose and moist",
            "Pod development & filling (కాయలో పప్పు నిండే దశ)",
        ],
        "criticalStagesTe": [
            "ఊడలు నేలలోకి దిగే దశ (Pegging) - నేల మెత్తగా తేమగా ఉండాలి",
            "కాయ ఊరే దశ (Pod filling)",
        ],
        "awdRecommended": False,
        "baseEt0": 5.0,
    },
    "sugarcane": {
        "nameEn": "Sugarcane",
        "nameTe": "చెరకు (Sugarcane)",
        "kc": {
            "Initial / Seedling": 0.50,
            "Vegetative": 0.90,
            "Flowering / Critical": 1.25,
            "Maturity / Ripening": 0.75,
        },
        "criticalStagesEn": [
            "Formative phase / Tillering (పిలకల దశ)",
            "Grand growth phase / Stalk elongation (గడ పెరిగే దశ)",
        ],
        "criticalStagesTe": [
            "పిలకలు తొడిగే దశ (Tillering phase)",
            "గడ వేగంగా పెరిగే దశ (Grand growth phase)",
        ],
        "awdRecommended": False,
        "baseEt0": 5.6,
    },
    "tomato": {
        "nameEn": "Tomato",
        "nameTe": "టమాటా (Tomato)",
        "kc": {
            "Initial / Seedling": 0.45,
            "Vegetative": 0.75,
            "Flowering / Critical": 1.15,
            "Maturity / Ripening": 0.75,
        },
        "criticalStagesEn": [
            "Flowering & Fruit setting - Inconsistent watering causes blossom end rot and fruit cracking",
            "Fruit enlargement",
        ],
        "criticalStagesTe": [
            "పూత మరియు కాయ కట్టే దశ - నీటి హెచ్చుతగ్గుల వల్ల కాయ పగుళ్లు వస్తాయి",
            "కాయ నిగారింపు & పరిమాణం పెరిగే దశ",
        ],
        "awdRecommended": False,
        "baseEt0": 5.2,
    },
    "wheat": {
        "nameEn": "Wheat",
        "nameTe": "గోధుమ (Wheat)",
        "kc": {
            "Initial / Seedling": 0.35,
            "Vegetative": 0.75,
            "Flowering / Critical": 1.15,
            "Maturity / Ripening": 0.60,
        },
        "criticalStagesEn": [
            "Crown Root Initiation (CRI at 21 DAS) - Most sensitive; delay drastically lowers tillers",
            "Flowering and Heading stage",
        ],
        "criticalStagesTe": [
            "మొదటి నీటి తడి (CRI దశ - 21వ రోజు) - ఆలస్యం చేస్తే పిలకలు తగ్గిపోతాయి",
            "కంకి వేసే దశ మరియు పూత దశ",
        ],
        "awdRecommended": False,
        "baseEt0": 4.5,
    },
}

PUMP_FLOW_RATES_LPH: Dict[float, float] = {
    3.0: 25000.0,   # 3 HP: ~25,000 Liters / hour
    5.0: 45000.0,   # 5 HP: ~45,000 Liters / hour
    7.5: 68000.0,   # 7.5 HP: ~68,000 Liters / hour
    10.0: 90000.0,  # 10 HP: ~90,000 Liters / hour
}

class IrrigationService:
    def _find_crop_data(self, query: str) -> Dict[str, Any]:
        q = query.lower().strip()
        for key, val in CROP_WATER_DATABASE.items():
            if key in q or val["nameEn"].lower() in q:
                return val
        return CROP_WATER_DATABASE["paddy"]

    def _convert_to_acres(self, area: float, unit: str) -> float:
        u = unit.lower()
        if "hectare" in u:
            return area * 2.47105
        elif "gunta" in u:
            return area * 0.025
        return area

    def calculate_irrigation_advice(self, req: IrrigationCalculationRequest) -> IrrigationAdviceResponse:
        crop_data = self._find_crop_data(req.crop)
        area_in_acres = self._convert_to_acres(req.area, req.unit)
        is_telugu = req.languageId.lower() == "te"

        # 1. Calculate Crop Evapotranspiration ETc
        base_et0 = crop_data.get("baseEt0", 5.2)  # mm/day
        stage_kc = crop_data["kc"].get(req.growthStage, 1.0)
        etc_mm = base_et0 * stage_kc

        # 1 mm of water over 1 acre = 4,046.86 Liters
        net_water_per_acre_liters = etc_mm * 4046.86

        # Application Efficiency by Method
        method_str = req.irrigationMethod.lower()
        if "drip" in method_str:
            eff = 0.90
        elif "sprinkler" in method_str:
            eff = 0.75
        elif "awd" in method_str or "alternate" in method_str:
            eff = 0.72
        else: # Furrow / Flood
            eff = 0.50

        gross_water_per_acre_liters = net_water_per_acre_liters / eff
        total_daily_water_liters = gross_water_per_acre_liters * area_in_acres

        # 2. Soil Moisture & Interval based on Soil Type
        soil_lower = req.soilType.lower()
        if "black" in soil_lower or "clay" in soil_lower:
            interval_days = 7
            soil_moisture_pct = 68
            soil_status = "Optimal"
        elif "red" in soil_lower or "loam" in soil_lower:
            interval_days = 4
            soil_moisture_pct = 48
            soil_status = "Needs Water"
        elif "sandy" in soil_lower:
            interval_days = 2
            soil_moisture_pct = 36
            soil_status = "Needs Water"
        else:
            interval_days = 5
            soil_moisture_pct = 55
            soil_status = "Optimal"

        # 3. Rain Forecast Evaluation
        should_irrigate = True
        weather_notice = ""
        if req.rainForecastMm >= 10.0:
            should_irrigate = False
            if is_telugu:
                weather_notice = f"వర్ష సూచన హెచ్చరిక: రాబోయే 48 గంటల్లో సుమారు {req.rainForecastMm:.0f} మి.మీ వర్షపాతం నమోదయ్యే అవకాశం ఉంది. కాబట్టి నీటిపారుదలను 2-3 రోజులు వాయిదా వేయండి. విద్యుత్ మరియు నీరు ఆదా అవుతాయి!"
            else:
                weather_notice = f"Rain Delay Advisory: Substantial rainfall (~{req.rainForecastMm:.0f} mm) is forecasted in the next 48 hours. Hold off on surface irrigation to prevent waterlogging and conserve electricity."
        else:
            if is_telugu:
                weather_notice = "వాతావరణం పొడిగా ఉంది. సూచించిన మోతాదు ప్రకారం నిర్ణీత సమయానికి నీటి తడులు ఇవ్వండి."
            else:
                weather_notice = "Weather conditions are dry and clear. Follow the recommended irrigation run times."

        # 4. Pump Runtime Calculation
        pump_hp = req.pumpHorsepower if req.pumpHorsepower in PUMP_FLOW_RATES_LPH else 5.0
        pump_lph = PUMP_FLOW_RATES_LPH.get(pump_hp, 45000.0)
        runtime_hours = total_daily_water_liters / pump_lph
        runtime_minutes = int(round(runtime_hours * 60))

        # Best time to irrigate
        if is_telugu:
            best_time = "ఉదయం 6:00 నుండి 9:00 గంటల మధ్య లేదా సాయంత్రం 4:30 తర్వాత (ఎండలో నీరు ఆవిరి కాకుండా కాపాడుతుంది)"
        else:
            best_time = "Early morning (6:00 AM - 9:00 AM) or late evening (after 4:30 PM) to minimize evaporation losses"

        # 5. Build 7-Day Schedule
        seven_day_schedule: List[IrrigationScheduleItem] = []
        now = datetime.now()
        for i in range(7):
            day_date = now + timedelta(days=i)
            day_name = day_date.strftime("%A")
            formatted_date = day_date.strftime("%d %b")

            # Determine whether this day is an irrigation day
            if not should_irrigate and i < 2:
                day_irrigate = False
                note = "Rain forecasted (Hold off)" if not is_telugu else "వర్ష సూచన (తడి నిలిపివేయండి)"
            elif i % max(1, interval_days // 2) == 0:
                day_irrigate = True
                note = "Scheduled watering window" if not is_telugu else "నిర్ణీత నీటి తడి సమయం"
            else:
                day_irrigate = False
                note = "Soil moisture adequate" if not is_telugu else "నేలలో తగినంత తేమ ఉంది"

            day_runtime = runtime_minutes if day_irrigate else 0
            day_vol = round(total_daily_water_liters, 0) if day_irrigate else 0.0

            action_summary = (
                f"{day_runtime} mins pump run ({int(day_vol):,} L)"
                if day_irrigate
                else ("Rest day - No watering" if not is_telugu else "విశ్రాంతి రోజు - నీరు అవసరం లేదు")
            )

            seven_day_schedule.append(
                IrrigationScheduleItem(
                    dayOffset=i,
                    dayName=day_name,
                    dateFormatted=formatted_date,
                    shouldIrrigate=day_irrigate,
                    recommendedRunTimeMinutes=day_runtime,
                    waterVolumeLiters=day_vol,
                    actionSummary=action_summary,
                    weatherSyncNote=note,
                )
            )

        # 6. Methods Comparison
        methods_comp: List[IrrigationMethodComparison] = [
            IrrigationMethodComparison(
                method="Drip Irrigation (బిందు సేద్యం)",
                localMethodName="బిందు సేద్యం (Drip Irrigation)" if is_telugu else "Drip Irrigation",
                waterEfficiencyPercent=90,
                waterLitersPerAcrePerDay=round(net_water_per_acre_liters / 0.90, 0),
                pumpRunHours=round((net_water_per_acre_liters / 0.90 * area_in_acres) / pump_lph, 2),
                waterSavingsPercent=45,
                fertigationSupported=True,
                keyRecommendation=(
                    "రైతులకు అత్యుత్తమ పద్ధతి. నీటితో పాటు ద్రవ ఎరువులను (Fertigation) నేరుగా వేర్లకు అందించవచ్చు. 45% నీరు ఆదా అవుతుంది."
                    if is_telugu else
                    "Highest efficiency. Direct root zone delivery with fertigation capability. Saves up to 45% water."
                )
            ),
            IrrigationMethodComparison(
                method="Sprinkler Irrigation (తుంపర సేద్యం)",
                localMethodName="తుంపర సేద్యం (Sprinkler)" if is_telugu else "Sprinkler Irrigation",
                waterEfficiencyPercent=75,
                waterLitersPerAcrePerDay=round(net_water_per_acre_liters / 0.75, 0),
                pumpRunHours=round((net_water_per_acre_liters / 0.75 * area_in_acres) / pump_lph, 2),
                waterSavingsPercent=30,
                fertigationSupported=False,
                keyRecommendation=(
                    "వేరుశనగ, పప్పుధాన్యాలు మరియు గోధుమ పంటలకు అనుకూలం. నేల కోతను నివారిస్తుంది."
                    if is_telugu else
                    "Ideal for groundnut, pulses, and wheat on undulating terrain. Saves 30% water."
                )
            ),
            IrrigationMethodComparison(
                method="Flood / Furrow Irrigation (బోదె సాగు)",
                localMethodName="బోదె సాగు / వెల్లువ సాగు" if is_telugu else "Furrow / Flood Irrigation",
                waterEfficiencyPercent=50,
                waterLitersPerAcrePerDay=round(net_water_per_acre_liters / 0.50, 0),
                pumpRunHours=round((net_water_per_acre_liters / 0.50 * area_in_acres) / pump_lph, 2),
                waterSavingsPercent=0,
                fertigationSupported=False,
                keyRecommendation=(
                    "సాంప్రదాయ పద్ధతి. ఆవిరి మరియు భూగర్భ ఇంకుడు వల్ల 50% నీరు వృథా అవుతుంది. ప్రత్యామ్నాయ బోదెల పద్ధతి పాటించండి."
                    if is_telugu else
                    "Traditional method with 50% conveyance and percolation losses. Use alternate furrow irrigation to save water."
                )
            ),
        ]

        if crop_data.get("awdRecommended", False):
            methods_comp.insert(
                1,
                IrrigationMethodComparison(
                    method="Alternate Wetting & Drying (AWD - ఆరుతడుల పద్ధతి)",
                    localMethodName="వరిలో ఆరుతడుల పద్ధతి (AWD)" if is_telugu else "Alternate Wetting & Drying (AWD)",
                    waterEfficiencyPercent=75,
                    waterLitersPerAcrePerDay=round(net_water_per_acre_liters / 0.72, 0),
                    pumpRunHours=round((net_water_per_acre_liters / 0.72 * area_in_acres) / pump_lph, 2),
                    waterSavingsPercent=30,
                    fertigationSupported=False,
                    keyRecommendation=(
                        "వరిలో నీటిని ఎల్లప్పుడూ నిల్వ ఉంచకుండా 1-2 రోజులు ఆరనిచ్చి మళ్ళీ నీరు పెట్టడం ద్వారా 30% నీరు మరియు కరెంట్ ఆదా అవుతుంది."
                        if is_telugu else
                        "In rice cultivation, allowing fields to dry intermittently saves 30% water and curbs methane emissions without yield penalty."
                    )
                )
            )

        # 7. Water Saving Tips
        if is_telugu:
            water_saving_tips = [
                "వరిలో ఆరుతడుల పద్ధతి (AWD) పాటించడం వల్ల 30% నీరు ఆదా అవుతుంది మరియు వేరు కుళ్ళు తగ్గుతుంది.",
                "తోట పంటల్లో ప్లాస్టిక్ లేదా ఎండుగడ్డితో మల్చింగ్ (Mulching) చేయడం వల్ల 30-40% నేల తేమ ఆవిరి కాకుండా కాపాడుకోవచ్చు.",
                "నీటిపారుదలను ఉదయం వేళల్లో లేదా సాయంత్రం వేళల్లో మాత్రమే చేయండి; మధ్యాహ్నపు ఎండలో నీరు త్వరగా ఆవిరి అయిపోతుంది.",
                "బోదెల పద్ధతిలో ఒక బోదె విడిచి ఒక బోదెకు నీరు పెట్టే 'Alternate Furrow' పద్ధతి ద్వారా సగం నీరు ఆదా చేయవచ్చు."
            ]
            summary = f"{req.area} {req.unit} {crop_data['nameTe']} పంటకు రోజువారీ నీటి అవసరం సుమారు {int(total_daily_water_liters):,} లీటర్లు. {pump_hp} HP మోటార్‌తో సుమారు {runtime_minutes} నిమిషాలు నడపాలి."
        else:
            water_saving_tips = [
                "Practice Alternate Wetting & Drying (AWD) in paddy fields using a perforated field water tube to conserve up to 30% water.",
                "Use organic straw or plastic mulching to preserve 30-40% soil moisture and prevent weed competition.",
                "Schedule irrigation in early mornings or evenings to avoid extreme evapotranspiration during afternoon heat.",
                "Adopt Alternate Furrow Irrigation in row crops (cotton, maize, sugarcane) to cut water use by up to 35% without yield impact."
            ]
            summary = f"Daily water requirement for {req.area} {req.unit} of {crop_data['nameEn']} is ~{int(total_daily_water_liters):,} Liters. Recommended {pump_hp} HP pump runtime is {runtime_minutes} minutes."

        critical_stages = crop_data["criticalStagesTe"] if is_telugu else crop_data["criticalStagesEn"]

        # Subsidy Info
        subsidy_info = {
            "schemeName": "APMIP / PMKSY (ప్రధాన మంత్రి కృషి సించాయి యోజన)" if is_telugu else "PMKSY / State Micro-Irrigation Projects",
            "subsidyRate": "70% to 90% Subsidy for Small & Marginal Farmers" if not is_telugu else "చిన్న మరియు సన్నకారు రైతులకు 70% నుండి 90% సబ్సిడీ",
            "eligibleSystems": "Drip Irrigation & Sprinkler Systems" if not is_telugu else "బిందు సేద్యం (Drip) మరియు తుంపర సేద్యం (Sprinkler) పరికరాలు",
            "howToApply": "Apply online at your nearest Rythu Bharosa Kendra (RBK) / MeeSeva with Passbook and Aadhaar." if not is_telugu else "మీ సమీప రైతు భరోసా కేంద్రం (RBK) లేదా మీసేవ ద్వారా పట్టాదారు పాస్‌బుక్, ఆధార్ కార్డుతో దరఖాస్తు చేసుకోవచ్చు.",
        }

        return IrrigationAdviceResponse(
            crop=crop_data["nameEn"],
            cropLocalName=crop_data["nameTe"] if is_telugu else crop_data["nameEn"],
            area=req.area,
            unit=req.unit,
            areaInAcres=round(area_in_acres, 2),
            growthStage=req.growthStage,
            soilType=req.soilType,
            irrigationMethod=req.irrigationMethod,
            soilMoistureStatus=soil_status,
            estimatedSoilMoisturePercent=soil_moisture_pct,
            shouldIrrigateToday=should_irrigate,
            dailyWaterRequirementLiters=round(total_daily_water_liters, 0),
            dailyWaterRequirementPerAcreLiters=round(gross_water_per_acre_liters, 0),
            pumpRuntimeMinutes=runtime_minutes,
            irrigationIntervalDays=interval_days,
            summary=summary,
            weatherSyncNotice=weather_notice,
            bestTimeToIrrigate=best_time,
            sevenDaySchedule=seven_day_schedule,
            methodsComparison=methods_comp,
            criticalStages=critical_stages,
            waterSavingTips=water_saving_tips,
            subsidyInfo=subsidy_info,
        )

# Global singleton
irrigation_service = IrrigationService()
