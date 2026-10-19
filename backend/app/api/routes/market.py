from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from app.schemas.market import MarketResponse, MarketAIInsight
from app.services.market_service import market_service
from app.services.ai_service import ai_service
import json
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/prices", response_model=MarketResponse)
async def get_market_prices(
    crop: str = Query(..., description="The name of the crop"),
    state: Optional[str] = Query(None, description="The state location"),
    district: Optional[str] = Query(None, description="The district location"),
    language: Optional[str] = Query("en", description="Requested language code")
):
    try:
        prices = await market_service.get_prices(crop=crop, state=state, district=district)
        
        if not prices:
            # We return empty array and success, the client handles empty as "Data Unavailable"
            return MarketResponse(data=[], status="success", message="No market price was found for this crop and selected location.")

        # Compute best market and baseline heuristics
        highest_p = max(prices, key=lambda p: p.modalPrice)
        best_market_desc = f"{highest_p.market} ({highest_p.district}) - ₹{highest_p.modalPrice:,.0f}/Qtl"

        # Attempt AI market trend analysis
        insight_obj = None
        try:
            records_summary = [
                {"market": p.market, "district": p.district, "modalPrice": p.modalPrice, "variety": p.variety}
                for p in prices[:6]
            ]
            ai_resp_str = await ai_service.analyze_market_insights(
                crop=crop,
                prices=records_summary,
                language_code=language or "en"
            )
            ai_data = json.loads(ai_resp_str)
            insight_obj = MarketAIInsight(**ai_data)
        except Exception as ai_err:
            logger.warning(f"AI market insight error: {ai_err}. Using fallback heuristic.")
            
            # Localized fallback descriptors
            headlines = {
                "te": f"{crop.title()} మార్కెట్ ధరలు రీజినల్ ఏపీఎంసీ మార్కెట్లలో స్థిరంగా ఉన్నాయి.",
                "hi": f"{crop.title()} के बाजार भाव क्षेत्रीय मंडियों में स्थिर बने हुए हैं।",
                "ta": f"{crop.title()} சந்தை விலைகள் நிலையான போக்கில் உள்ளன.",
                "kn": f"{crop.title()} ಮಾರುಕಟ್ಟೆ ದರಗಳು ಸ್ಥಿರವಾಗಿವೆ.",
                "ml": f"{crop.title()} വിപണി നിരക്കുകൾ സ്ഥിരത പുലർത്തുന്നു.",
                "mr": f"{crop.title()} बाजारभाव प्रादेशिक बाजारात स्थिर आहेत.",
                "bn": f"{crop.title()} বাজারের দর স্থিতিশীল রয়েছে।",
                "gu": f"{crop.title()} બજાર ભાવો સ્થિર વલણ દર્શાવે છે.",
                "pa": f"{crop.title()} ਮੰਡੀ ਭਾਅ ਖੇਤਰੀ ਮੰਡੀਆਂ ਵਿੱਚ ਸਥਿਰ ਹਨ।",
                "en": f"{crop.title()} market rates are holding steady across regional APMC mandis."
            }
            advisories = {
                "te": f"అత్యధిక ధర {highest_p.market} మార్కెట్‌లో లభిస్తోంది. పంటను నాణ్యతా ప్రమాణాల ప్రకారం గ్రేడింగ్ చేసి విక్రయించండి.",
                "hi": f"सर्वोच्च भाव {highest_p.market} मंडी में दर्ज है। उपज को साफ और श्रेणीबद्ध करके ले जाएं।",
                "ta": f"அதிகபட்ச விலை {highest_p.market} சந்தையில் கிடைக்கிறது. தரம்பிரித்து விற்பனை செய்யவும்.",
                "kn": f"ಗರಿಷ್ಠ ದರ {highest_p.market} ಮಾರುಕಟ್ಟೆಯಲ್ಲಿದೆ. ಗುಣಮಟ್ಟಕ್ಕೆ ತಕ್ಕಂತೆ ವರ್ಗೀಕರಿಸಿ ಮಾರಾಟ ಮಾಡಿ.",
                "ml": f"ഏറ്റവും ഉയർന്ന നിരക്ക് {highest_p.market} മാർക്കറ്റിലാണ്. തരംതിരിച്ച് വിൽക്കുക.",
                "mr": f"सर्वाधिक दर {highest_p.market} मार्केटमध्ये नोंदवला आहे. प्रतवारी करून विका.",
                "bn": f"সর্বোচ্চ দাম {highest_p.market} বাজারে পাওয়া যাচ্ছে। মান নির্ধারণ করে বিক্রি করুন।",
                "gu": f"સૌથી વધુ ભાવ {highest_p.market} માર્કેટમાં છે. ગ્રેડિંગ કરીને વેચો.",
                "pa": f"ਸਭ ਤੋਂ ਵੱਧ ਭਾਅ {highest_p.market} ਮੰਡੀ ਵਿੱਚ ਹੈ। ਚੰਗੀ ਤਰ੍ਹਾਂ ਛਾਂਟੀ ਕਰਕੇ ਵੇਚੋ।",
                "en": f"The highest rate reported is at {highest_p.market} mandi. Consider sorting and grading produce before bringing to market to fetch maximum modal price."
            }
            storage_tips = {
                "te": "మార్కెట్ కటింగ్స్ నివారించడానికి తేమ శాతం 12-14% లోపు ఉండేలా జాగ్రత్త వహించండి.",
                "hi": "कटौती से बचने के लिए नमी की मात्रा 12-14% से कम रखें।",
                "ta": "ஈரப்பதம் 12-14%க்குள் இருப்பதை உறுதிசெய்து விற்பனை இழப்பைத் தவிர்க்கவும்.",
                "kn": "ತೇವಾಂಶ 12-14% ರೊಳಗೆ ಇರುವಂತೆ ನೋಡಿಕೊಳ್ಳಿ.",
                "ml": "ഈർപ്പം 12-14% ൽ താഴെ നിലനിർത്തുക.",
                "mr": "कपात टाळण्यासाठी ओलावा 12-14% च्या आत ठेवा.",
                "bn": "আর্দ্রতা ১২-১৪% এর নিচে রাখুন।",
                "gu": "ભાવ કપાત ટાળવા માટે ભેજ 12-14% ની અંદર રાખો.",
                "pa": "ਕਟੌਤੀ ਤੋਂ ਬਚਣ ਲਈ ਨਮੀ 12-14% ਦੇ ਅੰਦਰ ਰੱਖੋ।",
                "en": "Ensure moisture content is below 12-14% to avoid moisture deduction or distress sale at mandi arrival."
            }
            trends = {
                "te": "స్థిరం (Steady)",
                "hi": "स्थिर (Steady)",
                "ta": "நிலையானது (Steady)",
                "kn": "ಸ್ಥಿರ (Steady)",
                "ml": "സ്ഥിരം (Steady)",
                "mr": "स्थिर (Steady)",
                "bn": "স্থিতিশীল (Steady)",
                "gu": "સ્થિર (Steady)",
                "pa": "ਸਥਿਰ (Steady)",
                "en": "Steady"
            }
            lang_key = (language or "en").lower()
            insight_obj = MarketAIInsight(
                headline=headlines.get(lang_key, headlines["en"]),
                bestMarket=best_market_desc,
                priceTrend=trends.get(lang_key, trends["en"]),
                advisory=advisories.get(lang_key, advisories["en"]),
                storageTip=storage_tips.get(lang_key, storage_tips["en"])
            )

        return MarketResponse(
            data=prices,
            status="success",
            message="Market prices retrieved successfully.",
            insight=insight_obj
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching market prices: {e}")
        raise HTTPException(status_code=500, detail="Market information is temporarily unavailable.")

