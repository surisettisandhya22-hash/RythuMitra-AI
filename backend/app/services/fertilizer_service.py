import math
from typing import Dict, Any, List
from app.schemas.fertilizer_schema import (
    FertilizerCalculationRequest,
    FertilizerRecommendationResponse,
    FertilizerBagItem,
    GrowthStageScheduleItem,
    StageFertilizerDose,
    OrganicAlternativeItem,
    MicronutrientItem,
    SupportedCropItem,
)

# Supported Crops Database with Regional Names
SUPPORTED_CROPS: List[Dict[str, Any]] = [
    {
        "id": "paddy",
        "nameEn": "Rice / Paddy",
        "nameTe": "వరి (Paddy / Rice)",
        "nameHi": "धान (Paddy)",
        "category": "Cereals",
        "icon": "grass",
        # N-P-K recommendation in kg per acre
        "npk": {"n": 48.0, "p": 24.0, "k": 20.0},
        # Standard commercial choices: 'dap_urea_mop' or 'ssp_urea_mop'
        "preferSsp": False,
        "stages": [
            {
                "nameEn": "Basal Application",
                "nameTe": "ఆఖరి దుక్కిలో / నాటేటప్పుడు",
                "timingEn": "Day 0 (At Transplanting / Sowing)",
                "timingTe": "నాట్లు వేసే సమయంలో (0వ రోజు)",
                "descEn": "Apply entire phosphorus and 50% potassium alongside 25% starter nitrogen to foster root development.",
                "descTe": "మొక్కల వేర్లు బలంగా నాటుకోవడానికి పూర్తి భాస్వరం (DAP/SSP), సగం పొటాష్ (MOP) మరియు 25% యూరియాను వేయాలి.",
                "splitRatios": {"urea": 0.25, "dap": 1.0, "ssp": 1.0, "mop": 0.50},
                "waterEn": "Maintain a thin film of water (1-2 cm) during transplanting; do not drain immediately.",
                "waterTe": "పొలంలో తేలికపాటి నీరు (1-2 సెం.మీ) నిలకడగా ఉండేలా చూడండి; ఎరువు వేసిన వెంటనే నీటిని బయటకు తీయవద్దు."
            },
            {
                "nameEn": "Active Tillering Stage",
                "nameTe": "మొదటి దఫా మేత (పిలకల దశ)",
                "timingEn": "20 - 25 Days After Transplanting (DAT)",
                "timingTe": "నాటిన 20 - 25 రోజులకు",
                "descEn": "Top dress nitrogen to stimulate vigorous tillering and lush canopy growth.",
                "descTe": "పిలకలు బాగా తొడగడానికి యూరియాను మొదటి దఫాగా వేసి కలుపు తీసిన తర్వాత పిచికారీ చేయాలి.",
                "splitRatios": {"urea": 0.50, "dap": 0.0, "ssp": 0.0, "mop": 0.0},
                "waterEn": "Drain excess stagnant water prior to broadcasting Urea, re-irrigate gently after 24 hours.",
                "waterTe": "యూరియా చల్లే ముందు పొలంలో నీటిని తగ్గించండి, చల్లిన 24 గంటల తర్వాత మళ్ళీ నీరు పెట్టండి."
            },
            {
                "nameEn": "Panicle Initiation Stage",
                "nameTe": "రెండవ దఫా మేత (చిరుపొట్ట / పూత దశ)",
                "timingEn": "45 - 55 Days After Transplanting (DAT)",
                "timingTe": "నాటిన 45 - 55 రోజులకు",
                "descEn": "Apply remaining nitrogen and potassium to ensure full grain setting and reduce unfilled grains.",
                "descTe": "కంకి బాగా ఏర్పడి, తాలు గింజలు తగ్గడానికి మిగిలిన యూరియా మరియు 50% పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 0.25, "dap": 0.0, "ssp": 0.0, "mop": 0.50},
                "waterEn": "Ensure adequate soil moisture (critical stage); water stress causes high unfilled grain percentage.",
                "waterTe": "ఈ దశలో నేలలో తేమ తప్పనిసరిగా ఉండాలి; నీటి ఎద్దడి వస్తే తాలు గింజల శాతం పెరుగుతుంది."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Zinc (జింక్)",
                "importanceEn": "Prevents Khaira disease and brown rusting on paddy seedling leaves.",
                "importanceTe": "వరిలో ఖైరా తెగులు (ఆకులు తుప్పు రంగులోకి మారడం) నివారణకు జింక్ అత్యవసరం.",
                "product": "Zinc Sulphate 21% (జింక్ సల్ఫేట్)",
                "dose": "10-12 kg per acre (ఆఖరి దుక్కిలో)",
                "timing": "Basal soil application. Never mix directly with DAP/Phosphates."
            }
        ]
    },
    {
        "id": "cotton",
        "nameEn": "Cotton",
        "nameTe": "ప్రత్తి (Cotton)",
        "nameHi": "कपास (Cotton)",
        "category": "Cash Crops",
        "icon": "local_florist",
        "npk": {"n": 60.0, "p": 24.0, "k": 24.0},
        "preferSsp": False,
        "stages": [
            {
                "nameEn": "Basal Application",
                "nameTe": "విత్తే ముందు / ఆఖరి దుక్కిలో",
                "timingEn": "Day 0 (At Sowing)",
                "timingTe": "విత్తే సమయంలో",
                "descEn": "Entire Phosphorus and 20% starter Nitrogen to support seedling root establishment.",
                "descTe": "మొలక దశలో వేర్లు బలంగా నాటుకోవడానికి పూర్తి భాస్వరం మరియు 20% యూరియా వేయాలి.",
                "splitRatios": {"urea": 0.20, "dap": 1.0, "ssp": 1.0, "mop": 0.30},
                "waterEn": "Ensure field has adequate residual moisture at sowing.",
                "waterTe": "విత్తే సమయంలో నేలలో సరైన పదును ఉండేలా చూసుకోండి."
            },
            {
                "nameEn": "Vegetative Branching Stage",
                "nameTe": "శాఖీయ దశ (మొదటి దఫా)",
                "timingEn": "30 - 35 Days After Sowing (DAS)",
                "timingTe": "విత్తిన 30 - 35 రోజులకు",
                "descEn": "Apply 40% Nitrogen to boost sympodial fruiting branches and leaf area.",
                "descTe": "కాయ కాసే కొమ్మలు బాగా రావడానికి 40% యూరియాను వేసి మట్టి ఎక్కించాలి.",
                "splitRatios": {"urea": 0.40, "dap": 0.0, "ssp": 0.0, "mop": 0.35},
                "waterEn": "Light irrigation after fertilizer application.",
                "waterTe": "ఎరువు వేసిన తర్వాత తేలికపాటి తడి అందించండి."
            },
            {
                "nameEn": "Square & Boll Formation Stage",
                "nameTe": "పూత & కాయ దశ (రెండవ దఫా)",
                "timingEn": "60 - 70 Days After Sowing (DAS)",
                "timingTe": "విత్తిన 60 - 70 రోజులకు",
                "descEn": "Apply remaining 40% Nitrogen and 35% Potash to enhance boll retention and boll weight.",
                "descTe": "పూత, పిందె రాలకుండా ఉండటానికి మరియు కాయ సైజు పెరగడానికి మిగిలిన యూరియా, పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 0.40, "dap": 0.0, "ssp": 0.0, "mop": 0.35},
                "waterEn": "Critical stage for irrigation; do not let soil crack.",
                "waterTe": "నేల బీటలు వారకుండా సకాలంలో నీటి తడులు ఇవ్వండి."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Magnesium & Boron (మెగ్నీషియం & బోరాన్)",
                "importanceEn": "Prevents reddening of cotton leaves and promotes square retention.",
                "importanceTe": "ప్రత్తిలో ఆకులు ఎర్రబడకుండా మెగ్నీషియం సల్ఫేట్, పూత రాలకుండా బోరాన్ సహాయపడతాయి.",
                "product": "Magnesium Sulphate (10 kg/ac) + Boron (1g/L foliar spray)",
                "dose": "Magnesium Sulphate 10 kg/acre soil application",
                "timing": "At 45 and 65 DAS along with regular sprays."
            }
        ]
    },
    {
        "id": "chilli",
        "nameEn": "Chilli",
        "nameTe": "మిరప (Chilli)",
        "nameHi": "मिर्च (Chilli)",
        "category": "Spices / Vegetables",
        "icon": "eco",
        "npk": {"n": 72.0, "p": 32.0, "k": 32.0},
        "preferSsp": False,
        "stages": [
            {
                "nameEn": "Basal Dressing",
                "nameTe": "నాటే ముందు (ఆఖరి దుక్కిలో)",
                "timingEn": "Day 0 (Transplanting)",
                "timingTe": "నాట్లు వేసే సమయంలో",
                "descEn": "Full Phosphorus, 25% Potassium and starter Nitrogen along with well-rotted farmyard manure.",
                "descTe": "మొక్కల ఎదుగుదలకు పూర్తి భాస్వరం, 25% పొటాష్ మరియు 20% యూరియాతో పాటు పశువుల ఎరువు వేయాలి.",
                "splitRatios": {"urea": 0.20, "dap": 1.0, "ssp": 1.0, "mop": 0.25},
                "waterEn": "Provide light irrigation immediately after seedling transplantation.",
                "waterTe": "మొక్కలు నాటిన వెంటనే తేలికపాటి తడి అందించండి."
            },
            {
                "nameEn": "First Top Dressing (Vegetative)",
                "nameTe": "మొదటి దఫా (శాఖీయ దశ)",
                "timingEn": "30 Days After Transplanting",
                "timingTe": "నాటిన 30 రోజులకు",
                "descEn": "Top dress 30% Nitrogen to boost vigorous branching.",
                "descTe": "కొమ్మలు బాగా విస్తరించడానికి 30% యూరియా వేయాలి.",
                "splitRatios": {"urea": 0.30, "dap": 0.0, "ssp": 0.0, "mop": 0.25},
                "waterEn": "Irrigate in furrows avoiding standing water near plant collars.",
                "waterTe": "బోదెల్లో నీరు పారించండి, మొదళ్ల వద్ద నీరు నిల్వ ఉండకుండా చూడండి."
            },
            {
                "nameEn": "Flowering & Fruit Setting Stage",
                "nameTe": "రెండవ దఫా (పూత & కాయ దశ)",
                "timingEn": "60 Days After Transplanting",
                "timingTe": "నాటిన 60 రోజులకు",
                "descEn": "Apply 30% Nitrogen and 25% Potassium to promote flower retention and green chilli length.",
                "descTe": "పూత పిందె బాగా నిలవడానికి 30% యూరియా మరియు 25% పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 0.30, "dap": 0.0, "ssp": 0.0, "mop": 0.25},
                "waterEn": "Even soil moisture is essential to prevent flower drop.",
                "waterTe": "పూత రాలకుండా ఉండాలంటే తేమ సమతుల్యంగా ఉండాలి."
            },
            {
                "nameEn": "Fruit Development & Picking",
                "nameTe": "మూడవ దఫా (కాయ కోత దశ)",
                "timingEn": "90 Days After Transplanting",
                "timingTe": "నాటిన 90 రోజులకు",
                "descEn": "Apply balance 20% Nitrogen and 25% Potassium to sustain multiple pickings.",
                "descTe": "కోతల తర్వాత మళ్ళీ కొత్త పూత రావడానికి మిగిలిన 20% యూరియా, 25% పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 0.20, "dap": 0.0, "ssp": 0.0, "mop": 0.25},
                "waterEn": "Regular light irrigations between pickings.",
                "waterTe": "కోతల మధ్య క్రమం తప్పకుండా తేలికపాటి తడులు ఇవ్వండి."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Calcium, Boron & Zinc (కాల్షియం, బోరాన్)",
                "importanceEn": "Prevents blossom end rot, tip burning, and fruit cracking.",
                "importanceTe": "కాయ కుళ్ళు, తొడిమ కుళ్ళు మరియు కాయ పగుళ్లు నివారించడానికి కాల్షియం, బోరాన్ ఎంతో ముఖ్యం.",
                "product": "Chelated Zinc (1g/L) + Boron 20% (1g/L foliar spray)",
                "dose": "Foliar spray at 40 and 70 DAT",
                "timing": "Spray during evening hours."
            }
        ]
    },
    {
        "id": "maize",
        "nameEn": "Maize / Corn",
        "nameTe": "మొక్కజొన్న (Maize)",
        "nameHi": "मक्का (Maize)",
        "category": "Cereals",
        "icon": "grain",
        "npk": {"n": 50.0, "p": 24.0, "k": 20.0},
        "preferSsp": False,
        "stages": [
            {
                "nameEn": "Basal Application",
                "nameTe": "ఆఖరి దుక్కిలో",
                "timingEn": "Day 0 (At Sowing)",
                "timingTe": "విత్తే సమయంలో",
                "descEn": "Apply entire DAP/SSP and full Potassium along with 25% starter Nitrogen.",
                "descTe": "పూర్తి భాస్వరం మరియు పొటాష్‌తో పాటు 25% యూరియా వేయాలి.",
                "splitRatios": {"urea": 0.25, "dap": 1.0, "ssp": 1.0, "mop": 1.0},
                "waterEn": "Irrigate field before or immediately after sowing.",
                "waterTe": "విత్తే ముందు లేదా విత్తిన వెంటనే తడి ఇవ్వండి."
            },
            {
                "nameEn": "Knee-High Stage",
                "nameTe": "మోకాలు లోతు దశ (మొదటి దఫా)",
                "timingEn": "25 - 30 Days After Sowing",
                "timingTe": "విత్తిన 25 - 30 రోజులకు",
                "descEn": "Top dress 50% Nitrogen along the rows followed by earthing up.",
                "descTe": "మొక్కలు మోకాలు ఎత్తుకు పెరిగినప్పుడు 50% యూరియాను సాళ్ళ వెంట వేసి మట్టి ఎక్కించాలి.",
                "splitRatios": {"urea": 0.50, "dap": 0.0, "ssp": 0.0, "mop": 0.0},
                "waterEn": "Provide irrigation within 24 hours of fertilizer placement.",
                "waterTe": "ఎరువు వేసిన 24 గంటల్లో నీటి తడి ఇవ్వండి."
            },
            {
                "nameEn": "Tasseling & Silking Stage",
                "nameTe": "కంకి పూత & పాలుపోసుకునే దశ",
                "timingEn": "45 - 55 Days After Sowing",
                "timingTe": "విత్తిన 45 - 55 రోజులకు",
                "descEn": "Apply remaining 25% Nitrogen to guarantee complete grain filling on the cob tip.",
                "descTe": "కంకి చివర వరకు గింజలు నిండటానికి మిగిలిన 25% యూరియాను వేయాలి.",
                "splitRatios": {"urea": 0.25, "dap": 0.0, "ssp": 0.0, "mop": 0.0},
                "waterEn": "Most moisture-critical stage; drought stress causes barren cobs.",
                "waterTe": "ఈ దశలో నీటి ఎద్దడి రాకూడదు; నీరు లేకపోతే కంకిలో గింజ కట్టదు."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Zinc (జింక్ లోపం)",
                "importanceEn": "Maize is highly sensitive to Zinc deficiency ('White bud' symptom).",
                "importanceTe": "మొక్కజొన్నలో జింక్ లోపిస్తే ఆకులపై తెల్లటి చారలు (White Bud) వస్తాయి.",
                "product": "Zinc Sulphate 21% (జింక్ సల్ఫేట్)",
                "dose": "10 kg/acre soil application at sowing",
                "timing": "Basal application in soil."
            }
        ]
    },
    {
        "id": "groundnut",
        "nameEn": "Groundnut / Peanut",
        "nameTe": "వేరుశనగ (Groundnut)",
        "nameHi": "मूंगफली (Groundnut)",
        "category": "Oilseeds / Legumes",
        "icon": "spa",
        # Legumes fix N; require higher P and Gypsum for Calcium & Sulphur!
        "npk": {"n": 10.0, "p": 20.0, "k": 20.0},
        "preferSsp": True,  # SSP is ideal for groundnut due to 12% Sulphur!
        "stages": [
            {
                "nameEn": "Basal Application",
                "nameTe": "విత్తే సమయంలో (ఆఖరి దుక్కిలో)",
                "timingEn": "Day 0 (At Sowing)",
                "timingTe": "విత్తే సమయంలో",
                "descEn": "Apply entire SSP and MOP along with starter Urea. SSP provides vital Sulphur for oil synthesis.",
                "descTe": "నూనె శాతం పెరగడానికి అవసరమైన గంధకం కోసం SSP ని వాడండి. పూర్తి పొటాష్, యూరియా వేయండి.",
                "splitRatios": {"urea": 1.0, "dap": 1.0, "ssp": 1.0, "mop": 1.0},
                "waterEn": "Ensure light moisture for uniform germination.",
                "waterTe": "గింజలు సమానంగా మొలకెత్తడానికి సరైన పదును ఉండాలి."
            },
            {
                "nameEn": "Pegging & Pod Formation (Gypsum)",
                "nameTe": "ఊడలు దిగే దశ (జిప్సం వేయడం)",
                "timingEn": "35 - 45 Days After Sowing",
                "timingTe": "విత్తిన 35 - 45 రోజులకు",
                "descEn": "Top dress Gypsum (200 kg/acre) around plant roots. Calcium in gypsum solidifies pod shell and prevents 'pops' (empty pods).",
                "descTe": "ఊడలు నేలలోకి దిగి కాయలు గట్టిపడటానికి, తాలు కాయలు తగ్గడానికి ఎకరాకు 200 కిలోల జిప్సం వేసి మట్టి ఎక్కించాలి.",
                "splitRatios": {"urea": 0.0, "dap": 0.0, "ssp": 0.0, "mop": 0.0},
                "waterEn": "Soil must be loose and moist for pegs to penetrate.",
                "waterTe": "ఊడలు సులభంగా నేలలోకి దిగడానికి నేల మెత్తగా, తేమగా ఉండాలి."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Gypsum (జిప్సం - కాల్షియం & గంధకం)",
                "importanceEn": "Essential for groundnut pod filling, shell hardness, and preventing hollow pods.",
                "importanceTe": "కాయలో పప్పు బలంగా నిండటానికి, నూనె శాతం పెరగడానికి జిప్సం తప్పనిసరి.",
                "product": "Agricultural Gypsum (200 kg/acre)",
                "dose": "200 kg per acre at 40-45 DAS",
                "timing": "Broadcast close to plant base and mulch lightly with soil."
            },
            {
                "nutrient": "Iron / Ferrous Sulphate (ఇనుము లోపం)",
                "importanceEn": "Prevents iron chlorosis (yellowing of young top leaves) in alkaline soils.",
                "importanceTe": "సున్నపు నేలల్లో ఆకులు పాలిపోతే అన్నభేది (ఫెర్రస్ సల్ఫేట్) పిచికారీ చేయాలి.",
                "product": "Ferrous Sulphate (అన్నభేది 5g) + Citric acid (1g) per liter water",
                "dose": "Foliar spray 1-2 times",
                "timing": "When yellowing is noticed on young leaves."
            }
        ]
    },
    {
        "id": "sugarcane",
        "nameEn": "Sugarcane",
        "nameTe": "చెరకు (Sugarcane)",
        "nameHi": "गन्ना (Sugarcane)",
        "category": "Cash Crops",
        "icon": "park",
        "npk": {"n": 100.0, "p": 40.0, "k": 48.0},
        "preferSsp": False,
        "stages": [
            {
                "nameEn": "Basal Application",
                "nameTe": "నాటేటప్పుడు (బోదెల్లో)",
                "timingEn": "Day 0 (Planting)",
                "timingTe": "ముచ్చెలు నాటే సమయంలో",
                "descEn": "Apply entire DAP/SSP and 25% Nitrogen along with 25% Potash in the furrow below sets.",
                "descTe": "బోదెల్లో పూర్తి భాస్వరం, 25% యూరియా మరియు 25% పొటాష్ వేసి నాటాలి.",
                "splitRatios": {"urea": 0.25, "dap": 1.0, "ssp": 1.0, "mop": 0.25},
                "waterEn": "Irrigate furrows immediately after planting sets.",
                "waterTe": "ముచ్చెలు నాటిన వెంటనే బోదెల నిండా నీరు పారించాలి."
            },
            {
                "nameEn": "First Tillering Phase",
                "nameTe": "మొదటి మేత (పిలకల దశ)",
                "timingEn": "45 Days After Planting",
                "timingTe": "నాటిన 45 రోజులకు",
                "descEn": "Apply 35% Nitrogen to promote vigorous cane tillering.",
                "descTe": "పిలకలు బాగా రావడానికి 35% యూరియా వేసి తేలికపాటి గరిటె తవ్వకం చేయాలి.",
                "splitRatios": {"urea": 0.35, "dap": 0.0, "ssp": 0.0, "mop": 0.25},
                "waterEn": "Provide copious irrigation every 7-10 days.",
                "waterTe": "ప్రతి వారం లేదా 10 రోజులకు ఒకసారి నీటి తడి ఇవ్వండి."
            },
            {
                "nameEn": "Grand Growth & Earthing Up",
                "nameTe": "పెద్ద మేత & గట్లు ఎక్కించడం",
                "timingEn": "90 - 100 Days After Planting",
                "timingTe": "నాటిన 90 - 100 రోజులకు",
                "descEn": "Apply remaining 40% Nitrogen and 50% Potash, followed by final heavy earthing up.",
                "descTe": "గడ బరువు పెరగడానికి మిగిలిన 40% యూరియా, 50% పొటాష్ వేసి పెద్ద గట్లు ఎక్కించాలి.",
                "splitRatios": {"urea": 0.40, "dap": 0.0, "ssp": 0.0, "mop": 0.50},
                "waterEn": "Ensure sustained soil moisture during stem elongation.",
                "waterTe": "గడ పెరిగే దశలో ఎట్టి పరిస్థితుల్లోనూ నీటి ఎద్దడి రానీయవద్దు."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Zinc & Iron (జింక్ & ఇనుము)",
                "importanceEn": "Prevents chlorosis and boosts sugar recovery in ratoon and plant cane.",
                "importanceTe": "చెరకులో తీపి శాతం పెరగడానికి, ఆకులు పచ్చబడటానికి జింక్ సల్ఫేట్ అవసరం.",
                "product": "Zinc Sulphate 21% (15 kg/acre) + Ferrous Sulphate (10 kg/acre)",
                "dose": "Basal application at planting",
                "timing": "Applied in the furrows."
            }
        ]
    },
    {
        "id": "tomato",
        "nameEn": "Tomato",
        "nameTe": "టమాటా (Tomato)",
        "nameHi": "टमाटर (Tomato)",
        "category": "Vegetables",
        "icon": "soup_kitchen",
        "npk": {"n": 48.0, "p": 36.0, "k": 40.0},
        "preferSsp": False,
        "stages": [
            {
                "nameEn": "Basal Dressing",
                "nameTe": "నాటే ముందు (ఆఖరి దుక్కిలో)",
                "timingEn": "Day 0 (Transplanting)",
                "timingTe": "నాట్లు వేసే సమయంలో",
                "descEn": "Full Phosphorus, 30% Nitrogen, and 30% Potassium alongside organic compost.",
                "descTe": "మొక్కలు బలంగా నిలదొక్కుకోవడానికి పూర్తి భాస్వరం, 30% యూరియా, 30% పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 0.30, "dap": 1.0, "ssp": 1.0, "mop": 0.30},
                "waterEn": "Light irrigation around seedling root zone.",
                "waterTe": "నాటిన వెంటనే మొదళ్ల వద్ద తేలికపాటి తడి ఇవ్వండి."
            },
            {
                "nameEn": "Vegetative & Flowering",
                "nameTe": "శాఖీయ & పూత దశ",
                "timingEn": "25 - 30 Days After Transplanting",
                "timingTe": "నాటిన 25 - 30 రోజులకు",
                "descEn": "Apply 35% Nitrogen and 30% Potash to enhance flowering clusters.",
                "descTe": "పూత పిందె బాగా రావడానికి 35% యూరియా, 30% పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 0.35, "dap": 0.0, "ssp": 0.0, "mop": 0.30},
                "waterEn": "Regular drip or furrow watering; avoid wetting foliage.",
                "waterTe": "ఆకులపై నీరు పడకుండా బోదెల్లో లేదా డ్రిప్ ద్వారా నీరు ఇవ్వండి."
            },
            {
                "nameEn": "Fruit Development & Ripening",
                "nameTe": "కాయ సైజు & పక్వత దశ",
                "timingEn": "50 - 60 Days After Transplanting",
                "timingTe": "నాటిన 50 - 60 రోజులకు",
                "descEn": "Apply balance 35% Nitrogen and 40% Potash for glossy skin and firm fruits.",
                "descTe": "కాయ నిగారింపు, బరువు, నిల్వ సామర్థ్యం పెరగడానికి మిగిలిన యూరియా, పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 0.35, "dap": 0.0, "ssp": 0.0, "mop": 0.40},
                "waterEn": "Maintain uniform moisture; fluctuating water causes fruit cracking.",
                "waterTe": "కాయ పగుళ్లు రాకుండా నీటి తడులను సమాన వ్యవధుల్లో ఇవ్వండి."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Calcium Nitrate & Boron (కాల్షియం నైట్రేట్ & బోరాన్)",
                "importanceEn": "Crucial to stop Blossom End Rot (black rot at bottom of tomato) and fruit cracking.",
                "importanceTe": "టమాటా అడుగున నల్లటి మచ్చ (బ్లాసమ్ ఎండ్ రాట్) మరియు కాయ పగుళ్లు నివారించడానికి.",
                "product": "Calcium Nitrate (5g/L) + Boron (1g/L)",
                "dose": "Foliar spray twice during fruit development",
                "timing": "Spray 15 days apart in morning/evening."
            }
        ]
    },
    {
        "id": "wheat",
        "nameEn": "Wheat",
        "nameTe": "గోధుమ (Wheat)",
        "nameHi": "गेहूं (Wheat)",
        "category": "Cereals",
        "icon": "agriculture",
        "npk": {"n": 48.0, "p": 24.0, "k": 16.0},
        "preferSsp": False,
        "stages": [
            {
                "nameEn": "Basal Dressing",
                "nameTe": "విత్తే సమయంలో",
                "timingEn": "Day 0 (At Sowing)",
                "timingTe": "విత్తే సమయంలో",
                "descEn": "Full Phosphorus and Potassium along with 50% starter Nitrogen drilled into soil.",
                "descTe": "పూర్తి భాస్వరం, పొటాష్ మరియు సగం యూరియాను సాళ్ళలో వేయాలి.",
                "splitRatios": {"urea": 0.50, "dap": 1.0, "ssp": 1.0, "mop": 1.0},
                "waterEn": "Pre-sowing irrigation (Paleva) is mandatory for uniform germination.",
                "waterTe": "విత్తడానికి ముందు పదును ఉండేలా నీరు పెట్టాలి."
            },
            {
                "nameEn": "Crown Root Initiation (CRI)",
                "nameTe": "మొదటి నీటి తడి (CRI దశ)",
                "timingEn": "21 Days After Sowing",
                "timingTe": "విత్తిన 21 రోజులకు",
                "descEn": "Top dress remaining 50% Nitrogen right after first critical CRI irrigation.",
                "descTe": "మొదటి నీటి తడి తర్వాత మిగిలిన 50% యూరియాను పైపాటుగా వేయాలి.",
                "splitRatios": {"urea": 0.50, "dap": 0.0, "ssp": 0.0, "mop": 0.0},
                "waterEn": "Most critical irrigation of wheat crop; delay reduces tillers drastically.",
                "waterTe": "ఈ మొదటి తడి గోధుమ పంటకు జీవనాడి; ఆలస్యం చేయవద్దు."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Zinc Sulphate (జింక్)",
                "importanceEn": "Essential for tillering and earhead length in wheat.",
                "importanceTe": "కంకి పొడవు పెరగడానికి, పిలకలు ఎక్కువగా రావడానికి జింక్ దోహదపడుతుంది.",
                "product": "Zinc Sulphate 21% (10 kg/acre)",
                "dose": "10 kg/acre basal application",
                "timing": "Applied at land preparation."
            }
        ]
    },
    {
        "id": "pulses",
        "nameEn": "Red Gram / Pulses",
        "nameTe": "కంది / పప్పుధాన్యాలు (Red Gram)",
        "nameHi": "अरहर / दालें (Red Gram)",
        "category": "Pulses",
        "icon": "spa",
        "npk": {"n": 8.0, "p": 20.0, "k": 10.0},
        "preferSsp": True,
        "stages": [
            {
                "nameEn": "Basal Application",
                "nameTe": "విత్తే సమయంలో (ఆఖరి దుక్కిలో)",
                "timingEn": "Day 0 (At Sowing)",
                "timingTe": "విత్తే సమయంలో",
                "descEn": "Apply entire SSP/DAP and MOP with small starter nitrogen. Pulses fix atmospheric nitrogen via root nodules.",
                "descTe": "రైజోబియం ద్వారా గాలిలోని నత్రజనిని గ్రహిస్తాయి కాబట్టి కొద్దిపాటి యూరియా మరియు పూర్తి భాస్వరం, పొటాష్ వేయాలి.",
                "splitRatios": {"urea": 1.0, "dap": 1.0, "ssp": 1.0, "mop": 1.0},
                "waterEn": "Sow in rainfed conditions with good soil drainage.",
                "waterTe": "నీరు నిల్వ ఉండకుండా మురుగు నీటి సౌకర్యం ఉండేలా చూసుకోండి."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Rhizobium Culture & Zinc (రైజోబియం & జింక్)",
                "importanceEn": "Rhizobium biofertilizer seed treatment boosts root nodulation 3-fold.",
                "importanceTe": "విత్తనశుద్ధి రైజోబియం కల్చర్‌తో చేస్తే వేరుబుడిపెల సంఖ్య రెట్టింపు అవుతుంది.",
                "product": "Rhizobium (200g/acre seed treatment) + Zinc Sulphate",
                "dose": "Seed treatment with jaggery water solution",
                "timing": "Prior to sowing in shade."
            }
        ]
    },
    {
        "id": "onion",
        "nameEn": "Onion",
        "nameTe": "ఉల్లి (Onion)",
        "nameHi": "प्याज (Onion)",
        "category": "Vegetables",
        "icon": "circle",
        "npk": {"n": 40.0, "p": 24.0, "k": 32.0},
        "preferSsp": True,  # Sulphur is vital for onion pungency and storage life!
        "stages": [
            {
                "nameEn": "Basal Dressing",
                "nameTe": "నాటే ముందు (ఆఖరి దుక్కిలో)",
                "timingEn": "Day 0 (Transplanting)",
                "timingTe": "నాట్లు వేసే సమయంలో",
                "descEn": "Full Phosphorus (preferably SSP for Sulphur), full Potassium, and 30% Nitrogen.",
                "descTe": "ఘాటు మరియు నిల్వ సామర్థ్యం కోసం SSP రూపంలో పూర్తి భాస్వరం, పొటాష్ మరియు 30% యూరియా వేయాలి.",
                "splitRatios": {"urea": 0.30, "dap": 1.0, "ssp": 1.0, "mop": 0.50},
                "waterEn": "Provide light irrigation immediately upon transplanting seedlings.",
                "waterTe": "చిన్న నారు నాటిన వెంటనే తేలికపాటి తడి ఇవ్వండి."
            },
            {
                "nameEn": "Vegetative Growth",
                "nameTe": "మొదటి దఫా (శాఖీయ దశ)",
                "timingEn": "30 Days After Transplanting",
                "timingTe": "నాటిన 30 రోజులకు",
                "descEn": "Top dress 35% Nitrogen to promote healthy leaf foliage.",
                "descTe": "ఆకులు బలంగా ఎదగడానికి 35% యూరియా వేయాలి.",
                "splitRatios": {"urea": 0.35, "dap": 0.0, "ssp": 0.0, "mop": 0.0},
                "waterEn": "Avoid heavy pooling around onion necks.",
                "waterTe": "మొదళ్ల వద్ద నీరు ఆగకుండా చూసుకోండి."
            },
            {
                "nameEn": "Bulb Development Stage",
                "nameTe": "రెండవ దఫా (గడ్డ ఊరే దశ)",
                "timingEn": "45 - 50 Days After Transplanting",
                "timingTe": "నాటిన 45 - 50 రోజులకు",
                "descEn": "Apply balance 35% Nitrogen and 50% Potash to enhance bulb size and firmness. Stop nitrogen 20 days before harvest.",
                "descTe": "గడ్డ సైజు పెరగడానికి మిగిలిన యూరియా మరియు 50% పొటాష్ వేయాలి. కోతకు 20 రోజుల ముందు ఎరువులు ఆపేయాలి.",
                "splitRatios": {"urea": 0.35, "dap": 0.0, "ssp": 0.0, "mop": 0.50},
                "waterEn": "Gradually reduce water 15 days before harvest to cure skins.",
                "waterTe": "కోతకు 10-15 రోజుల ముందు నీరు నిలిపివేయాలి."
            }
        ],
        "micronutrients": [
            {
                "nutrient": "Sulphur (గంధకం)",
                "importanceEn": "Essential for pungency, flavor, and long storage life without rotting in godown.",
                "importanceTe": "ఉల్లిలో ఘాటు, రంగు మరియు ఎక్కువ కాలం నిల్వ ఉండటానికి గంధకం ఎంతో ముఖ్యం.",
                "product": "Bentonite Sulphur 90% (10 kg/acre) or SSP",
                "dose": "10 kg/acre basal application",
                "timing": "At final land preparation."
            }
        ]
    }
]

# Standard Indian Retail Subsidized Prices (INR)
PRICES = {
    "urea_45kg": 266.50,   # Subsidized Neem Coated Urea (45kg bag)
    "dap_50kg": 1350.00,   # Subsidized DAP 18:46:0 (50kg bag)
    "mop_50kg": 1700.00,   # Subsidized MOP 0:0:60 (50kg bag)
    "ssp_50kg": 500.00,    # Subsidized SSP 0:16:0 (50kg bag)
    "gypsum_50kg": 250.00, # Agricultural Gypsum
    "zinc_10kg": 600.00,   # Zinc Sulphate 21%
}

class FertilizerService:
    def get_supported_crops(self) -> List[SupportedCropItem]:
        return [
            SupportedCropItem(
                id=c["id"],
                nameEn=c["nameEn"],
                nameTe=c["nameTe"],
                nameHi=c["nameHi"],
                category=c["category"],
                icon=c["icon"],
            )
            for c in SUPPORTED_CROPS
        ]

    def _find_crop_data(self, query: str) -> Dict[str, Any]:
        q = query.lower().strip()
        for c in SUPPORTED_CROPS:
            if (
                c["id"] in q
                or c["nameEn"].lower() in q
                or q in c["nameEn"].lower()
                or ("paddy" in q and c["id"] == "paddy")
                or ("rice" in q and c["id"] == "paddy")
                or ("cotton" in q and c["id"] == "cotton")
                or ("chilli" in q and c["id"] == "chilli")
                or ("mirchi" in q and c["id"] == "chilli")
                or ("maize" in q and c["id"] == "maize")
                or ("corn" in q and c["id"] == "maize")
                or ("groundnut" in q and c["id"] == "groundnut")
                or ("peanut" in q and c["id"] == "groundnut")
                or ("sugarcane" in q and c["id"] == "sugarcane")
                or ("tomato" in q and c["id"] == "tomato")
                or ("wheat" in q and c["id"] == "wheat")
                or ("pulse" in q and c["id"] == "pulses")
                or ("gram" in q and c["id"] == "pulses")
                or ("onion" in q and c["id"] == "onion")
            ):
                return c
        # Default fallback to Paddy
        return SUPPORTED_CROPS[0]

    def _convert_to_acres(self, area: float, unit: str) -> float:
        u = unit.lower()
        if "hectare" in u:
            return area * 2.47105
        elif "gunta" in u:
            return area * 0.025 # 40 guntas = 1 acre
        elif "sq" in u or "meter" in u:
            return area * 0.000247105
        return area

    def calculate_fertilizer_plan(self, req: FertilizerCalculationRequest) -> FertilizerRecommendationResponse:
        crop_data = self._find_crop_data(req.crop)
        area_in_acres = self._convert_to_acres(req.area, req.unit)
        is_telugu = req.languageId.lower() == "te"

        # Baseline NPK recommended per acre
        n_per_acre = crop_data["npk"]["n"]
        p_per_acre = crop_data["npk"]["p"]
        k_per_acre = crop_data["npk"]["k"]

        # Total N, P, K in kg for farmer's land
        total_n = n_per_acre * area_in_acres
        total_p = p_per_acre * area_in_acres
        total_k = k_per_acre * area_in_acres

        use_ssp = crop_data.get("preferSsp", False)

        primary_fertilizers: List[FertilizerBagItem] = []
        total_cost = 0.0

        if use_ssp:
            # SSP provides 16% P2O5 and 12% Sulphur
            ssp_kg = total_p / 0.16
            ssp_bags = ssp_kg / 50.0
            ssp_cost = math.ceil(ssp_bags) * PRICES["ssp_50kg"]
            total_cost += ssp_cost
            primary_fertilizers.append(
                FertilizerBagItem(
                    name="SSP (Single Super Phosphate 16% P2O5)",
                    localName="సింగిల్ సూపర్ ఫాస్ఫేట్ (SSP)" if is_telugu else "SSP (Single Super Phosphate)",
                    nutrientType="Phosphorus (P) + 12% Sulphur",
                    quantityKg=round(ssp_kg, 1),
                    bagsCount=round(ssp_bags, 1),
                    bagWeightKg=50,
                    looseKgRemaining=round(ssp_kg % 50, 1),
                    estimatedPricePerBag=PRICES["ssp_50kg"],
                    totalEstimatedPrice=round(ssp_cost, 2),
                    applicationGuide=(
                        "ఆఖరి దుక్కిలో మట్టిలో కలిసేలా వేయాలి. గంధకం (Sulphur) ఉండటం వల్ల నూనె మరియు పంట నాణ్యత పెరుగుతుంది."
                        if is_telugu else
                        "Apply as basal dose during final plowing. Provides vital Sulphur along with Phosphate."
                    )
                )
            )
            # Urea supplies all N (Urea is 46% N, standard bag is 45 kg)
            urea_kg = total_n / 0.46
        else:
            # DAP provides 46% P2O5 and 18% N
            dap_kg = total_p / 0.46
            dap_bags = dap_kg / 50.0
            dap_cost = math.ceil(dap_bags) * PRICES["dap_50kg"]
            total_cost += dap_cost
            primary_fertilizers.append(
                FertilizerBagItem(
                    name="DAP (Di-Ammonium Phosphate 18:46:0)",
                    localName="డి.ఎ.పి (DAP 18:46:0)" if is_telugu else "DAP (Di-Ammonium Phosphate)",
                    nutrientType="Phosphorus (P) & Starter Nitrogen (N)",
                    quantityKg=round(dap_kg, 1),
                    bagsCount=round(dap_bags, 1),
                    bagWeightKg=50,
                    looseKgRemaining=round(dap_kg % 50, 1),
                    estimatedPricePerBag=PRICES["dap_50kg"],
                    totalEstimatedPrice=round(dap_cost, 2),
                    applicationGuide=(
                        "విత్తే సమయంలో లేదా నాటేటప్పుడు ఆఖరి దుక్కిలో వేయాలి. నేల లోపల 5-7 సెం.మీ లోతులో పడేలా చూడండి."
                        if is_telugu else
                        "Apply as basal dose at sowing/transplanting. Place 5-7 cm below seed level for best root absorption."
                    )
                )
            )
            # N supplied by DAP = dap_kg * 0.18
            n_from_dap = dap_kg * 0.18
            remaining_n = max(0.0, total_n - n_from_dap)
            urea_kg = remaining_n / 0.46

        # Urea calculation (Neem coated Urea = 46% N, 45 kg bag standard)
        urea_bags = urea_kg / 45.0
        urea_cost = math.ceil(urea_bags) * PRICES["urea_45kg"]
        total_cost += urea_cost
        primary_fertilizers.append(
            FertilizerBagItem(
                name="Neem Coated Urea (46% N)",
                localName="వేప పూత పూసిన యూరియా (46% N)" if is_telugu else "Neem Coated Urea (46% N)",
                nutrientType="Nitrogen (N) - Vegetative Growth",
                quantityKg=round(urea_kg, 1),
                bagsCount=round(urea_bags, 1),
                bagWeightKg=45,
                looseKgRemaining=round(urea_kg % 45, 1),
                estimatedPricePerBag=PRICES["urea_45kg"],
                totalEstimatedPrice=round(urea_cost, 2),
                applicationGuide=(
                    "దఫాల వారీగా విభజించి మాత్రమే వేయాలి. ఒకేసారి వేయవద్దు. నేలలో తగినంత తేమ ఉన్నప్పుడు సాయంత్రం వేళల్లో వేయడం ఉత్తమం."
                    if is_telugu else
                    "Apply strictly in splits across growth stages. Never apply all at once. Broadcast in moist soil during evening hours."
                )
            )
        )

        # MOP calculation (MOP is 60% K2O, 50 kg bag)
        mop_kg = total_k / 0.60
        mop_bags = mop_kg / 50.0
        mop_cost = math.ceil(mop_bags) * PRICES["mop_50kg"]
        total_cost += mop_cost
        primary_fertilizers.append(
            FertilizerBagItem(
                name="MOP (Muriate of Potash 60% K2O)",
                localName="పొటాష్ / ఎం.ఓ.పి (MOP 60% K2O)" if is_telugu else "MOP (Muriate of Potash 60% K2O)",
                nutrientType="Potassium (K) - Grain Quality & Disease Resistance",
                quantityKg=round(mop_kg, 1),
                bagsCount=round(mop_bags, 1),
                bagWeightKg=50,
                looseKgRemaining=round(mop_kg % 50, 1),
                estimatedPricePerBag=PRICES["mop_50kg"],
                totalEstimatedPrice=round(mop_cost, 2),
                applicationGuide=(
                    "కంకి లేదా పూత నాణ్యతకు, గింజ బరువు పెరగడానికి మరియు తెగుళ్ళ నిరోధకతకు పొటాష్ చాలా ముఖ్యం."
                    if is_telugu else
                    "Improves disease resistance, grain firmness, weight, and drought tolerance. Apply in 1-2 splits."
                )
            )
        )

        # Build Stage-Wise Schedule
        stages_list: List[GrowthStageScheduleItem] = []
        raw_stages = crop_data.get("stages", [])

        for st in raw_stages:
            ratios = st["splitRatios"]
            stage_doses: List[StageFertilizerDose] = []

            # Urea split
            stage_urea_kg = round(urea_kg * ratios.get("urea", 0.0), 1)
            if stage_urea_kg > 0:
                stage_doses.append(
                    StageFertilizerDose(
                        productName="Urea (యూరియా)" if is_telugu else "Urea (46% N)",
                        quantityKg=stage_urea_kg,
                        bagsApprox=f"{round(stage_urea_kg / 45.0, 1)} bags",
                        instruction="Top-dress evenly in soil moisture" if not is_telugu else "మట్టిలో తేమ ఉన్నప్పుడు సమానంగా చల్లండి"
                    )
                )

            # Phosphate split
            if use_ssp:
                stage_ssp_kg = round(ssp_kg * ratios.get("ssp", 0.0), 1)
                if stage_ssp_kg > 0:
                    stage_doses.append(
                        StageFertilizerDose(
                            productName="SSP (సింగిల్ సూపర్ ఫాస్ఫేట్)" if is_telugu else "SSP",
                            quantityKg=stage_ssp_kg,
                            bagsApprox=f"{round(stage_ssp_kg / 50.0, 1)} bags",
                            instruction="Incorporate into soil during plowing" if not is_telugu else "దుక్కిలో మట్టిలో కలిసేలా వేయాలి"
                        )
                    )
            else:
                stage_dap_kg = round(dap_kg * ratios.get("dap", 0.0), 1)
                if stage_dap_kg > 0:
                    stage_doses.append(
                        StageFertilizerDose(
                            productName="DAP (డి.ఎ.పి)" if is_telugu else "DAP (18:46:0)",
                            quantityKg=stage_dap_kg,
                            bagsApprox=f"{round(stage_dap_kg / 50.0, 1)} bags",
                            instruction="Basal placement in root zone" if not is_telugu else "మొలకల వేరు మండలంలో పడేలా వేయాలి"
                        )
                    )

            # Potash split
            stage_mop_kg = round(mop_kg * ratios.get("mop", 0.0), 1)
            if stage_mop_kg > 0:
                stage_doses.append(
                    StageFertilizerDose(
                        productName="MOP (పొటాష్)" if is_telugu else "MOP (Potash)",
                        quantityKg=stage_mop_kg,
                        bagsApprox=f"{round(stage_mop_kg / 50.0, 1)} bags",
                        instruction="Broadcast along root zone" if not is_telugu else "మొక్కల మొదళ్ల వద్ద చల్లాలి"
                    )
                )

            stages_list.append(
                GrowthStageScheduleItem(
                    stageName=st["nameTe"] if is_telugu else st["nameEn"],
                    timingDays=st["timingTe"] if is_telugu else st["timingEn"],
                    description=st["descTe"] if is_telugu else st["descEn"],
                    fertilizers=stage_doses,
                    waterPrecaution=st["waterTe"] if is_telugu else st["waterEn"],
                )
            )

        # Organic Alternatives
        vermicompost_dose = f"{int(round(1.5 * area_in_acres))} - {int(round(2.5 * area_in_acres))} Tonnes"
        jeevamrutham_dose = f"{int(round(200 * area_in_acres))} Liters per application (every 15-20 days)"
        neem_cake_dose = f"{int(round(100 * area_in_acres))} kg (ఆఖరి దుక్కిలో)" if is_telugu else f"{int(round(100 * area_in_acres))} kg (Basal plowing)"

        organic_items: List[OrganicAlternativeItem] = [
            OrganicAlternativeItem(
                name="Jeevamrutham (జీవామృతం)",
                localName="జీవామృతం" if is_telugu else "Jeevamrutham",
                quantityPerAcre=jeevamrutham_dose,
                benefits=(
                    "నేలలోని సూక్ష్మజీవులను మరియు వానపాములను క్రియాశీలం చేస్తుంది, నేల సారవంతాన్ని వేగంగా పెంచుతుంది."
                    if is_telugu else
                    "Enriches beneficial soil microbes, increases earthworm activity, and enhances nutrient bioavailability."
                ),
                applicationMethod=(
                    "200 లీటర్ల డ్రమ్ములో 10 కిలోల ఆవు పేడ, 10 లీటర్ల ఆవు మూత్రం, 2 కిలోల బెల్లం, 2 కిలోల శనగపిండి, పిడికెడు పుట్టమట్టి కలిపి 3 రోజులు నిల్వచేసి సాగునీటితో అందించాలి."
                    if is_telugu else
                    "Prepare with 10kg cow dung, 10L cow urine, 2kg jaggery, 2kg pulse flour in 200L water. Ferment for 3 days and apply via irrigation water."
                )
            ),
            OrganicAlternativeItem(
                name="Vermicompost (వానపాముల ఎరువు)",
                localName="వానపాముల ఎరువు" if is_telugu else "Vermicompost",
                quantityPerAcre=vermicompost_dose,
                benefits=(
                    "నేలలో సేంద్రీయ కర్బనాన్ని (Organic Carbon) పెంచుతుంది, నేల తేమను నిలుపుకునే శక్తిని రెట్టింపు చేస్తుంది."
                    if is_telugu else
                    "Supplies humic acids, enhances organic carbon, increases water retention and root aeration."
                ),
                applicationMethod=(
                    "ఆఖరి దుక్కిలో లేదా సాళ్లలో వేసి మట్టితో కలపాలి."
                    if is_telugu else
                    "Apply as basal manure during final ploughing or incorporate along plantation furrows."
                )
            ),
            OrganicAlternativeItem(
                name="Neem Cake (వేప పిండి)",
                localName="వేప పిండి" if is_telugu else "Neem Cake",
                quantityPerAcre=neem_cake_dose,
                benefits=(
                    "యూరియా నత్రజని ఆవిరి కాకుండా కాపాడుతుంది (Nitrification Inhibitor) మరియు వేరు పురుగులను, నెమటోడ్లను నివారిస్తుంది."
                    if is_telugu else
                    "Natural nitrification inhibitor; slows nitrogen leaching, controls root grubs and soil-borne nematodes."
                ),
                applicationMethod=(
                    "ఆఖరి దుక్కిలో వేయాలి లేదా యూరియాతో 5:1 నిష్పత్తిలో కలిపి 24 గంటల తర్వాత చల్లాలి."
                    if is_telugu else
                    "Broadcast during land preparation or blend with Urea (1 part neem cake to 5 parts urea)."
                )
            )
        ]

        # Micronutrient items
        micronutrient_items: List[MicronutrientItem] = []
        for m in crop_data.get("micronutrients", []):
            micronutrient_items.append(
                MicronutrientItem(
                    nutrient=m["nutrient"],
                    importance=m["importanceTe"] if is_telugu else m["importanceEn"],
                    recommendedProduct=m["product"],
                    dosagePerAcre=m["dose"],
                    applicationTiming=m["timing"]
                )
            )

        # Best Practices
        if is_telugu:
            best_practices = [
                "ఎరువులు వేసేటప్పుడు నేలలో తగినంత తేమ (పదును) ఉండేలా చూసుకోండి; ఎండలో వేయవద్దు.",
                "DAP మరియు యూరియాలను ముందుగానే కలిపి నిల్వ ఉంచవద్దు; వేసే సమయంలో మాత్రమే అవసరమైతే కలపండి.",
                "జింక్ సల్ఫేట్ మరియు DAP లేదా భాస్వరం ఎరువులను ఎప్పుడూ ఒకేసారి కలపకూడదు (రసాయన చర్య జరిగి జింక్ ఫాస్ఫేట్ గా మారి మొక్కలకు అందదు).",
                "అధిక యూరియా వాడకం వల్ల పంటకు ఆకుముడత, రసం పీల్చే పురుగులు మరియు తెగుళ్లు ఎక్కువగా వస్తాయి కాబట్టి సిఫార్సు చేసిన మోతాదు మాత్రమే వేయండి."
            ]
            warning_notes = "గమనిక: ఈ లెక్కలు ICAR మరియు వ్యవసాయ విశ్వవిద్యాలయాల ప్రామాణిక పరిశోధనల ఆధారంగా రూపొందించబడ్డాయి. నేల పరీక్ష ఫలితాల ఆధారంగా మోతాదును సర్దుబాటు చేసుకోవడం మంచిది."
            summary = f"{req.area} {req.unit} {crop_data['nameTe']} పంటకు శాస్త్రీయ ఎరువుల ప్రణాళిక రూపొందించబడింది. మొత్తం అంచనా వ్యయం ₹{round(total_cost, 0):,}."
        else:
            best_practices = [
                "Ensure optimum soil moisture when applying chemical fertilizers; avoid applying under harsh noon sun.",
                "Never store mixed Urea and DAP together; blend immediately prior to application if needed.",
                "Never mix Zinc Sulphate with DAP/Phosphatic fertilizers; they react to form insoluble Zinc Phosphate which roots cannot take up.",
                "Avoid excessive Nitrogen (Urea); surplus nitrogen causes vegetative overgrowth and attracts sucking pests (BPH, stem borer, aphids)."
            ]
            warning_notes = "Note: Recommended dosages align with ICAR & State Agricultural Universities standards. For exact field calibration, reference your Soil Health Card test values."
            summary = f"Scientific fertilizer management plan formulated for {req.area} {req.unit} of {crop_data['nameEn']}. Total estimated fertilizer expenditure is ₹{round(total_cost, 0):,}."

        return FertilizerRecommendationResponse(
            crop=crop_data["nameEn"],
            cropLocalName=crop_data["nameTe"] if is_telugu else crop_data["nameEn"],
            area=req.area,
            unit=req.unit,
            areaInAcres=round(area_in_acres, 2),
            farmingType=req.farmingType,
            summary=summary,
            totalEstimatedCost=round(total_cost, 2),
            primaryFertilizers=primary_fertilizers,
            growthStageSchedule=stages_list,
            organicAlternatives=organic_items,
            micronutrients=micronutrient_items,
            bestPractices=best_practices,
            warningNotes=warning_notes
        )

# Global singleton
fertilizer_service = FertilizerService()
