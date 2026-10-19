from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from app.schemas.soil_schema import (
    SoilDataInput,
    SoilHealthAnalysisResponse,
    SoilSamplingGuideResponse,
    SoilGuideStep,
)
from app.services.ai_service import ai_service
import json

router = APIRouter()

@router.get("/guide", response_model=SoilSamplingGuideResponse)
def get_soil_sampling_guide(languageId: str = "en"):
    """
    Returns step-by-step soil sampling guidelines (available in English, Telugu, Hindi).
    """
    lang = (languageId or "en").lower().strip()
    if lang == "te":
        return SoilSamplingGuideResponse(
            title="మట్టి నమూనా సేకరణ సమగ్ర మార్గదర్శి",
            importance="మట్టి పరీక్ష ద్వారా మీ నేలలోని పోషకాలు, pH విలువ మరియు కర్బన శాతాన్ని తెలుసుకొని సరైన ఎరువులు వేసి పెట్టుబడి ఖర్చును తగ్గించుకోవచ్చు.",
            bestTiming="విత్తనాలు నాటడానికి 1 నెల ముందు లేదా పంట కోత పూర్తయిన తర్వాత నమూనాలు సేకరించాలి. అధిక వర్షాలు లేదా ఎరువులు వేసిన వెంటనే సేకరించవద్దు.",
            steps=[
                SoilGuideStep(
                    stepNumber=1,
                    title="పొలంలో గుర్తులు పెట్టడం (Zig-Zag పద్ధతి)",
                    description="పొలం అంతటా ఒకే రకంగా కాకుండా 'జిగ్-జాగ్' (V ఆకారంలో) నడుస్తూ ఎకరాకు 8 నుండి 10 చోట్ల స్థలాలను గుర్తించండి. చెట్ల నీడ, గట్లు, కాలువల దగ్గర నమూనాలు తీయవద్దు.",
                    icon="map",
                    tips=["గట్ల నుండి కనీసం 2-3 మీటర్ల దూరం పాటించండి", "చెట్ల కింద లేదా పశువుల పెంట కుప్పల వద్ద తీయవద్దు"]
                ),
                SoilGuideStep(
                    stepNumber=2,
                    title="ఉపరితల శుభ్రత",
                    description="గుర్తించిన ప్రదేశంలో పైనున్న చెత్తాచెదారం, గడ్డి, కలుపు మొక్కలను పారతో తేలికగా తొలగించండి.",
                    icon="cleaning_services",
                    tips=["పై పొరలోని 1-2 సెంటీమీటర్ల దుమ్ము/చెత్త మాత్రమే తొలగించండి, మట్టిని తవ్వొద్దు"]
                ),
                SoilGuideStep(
                    stepNumber=3,
                    title="'V' ఆకారంలో గుంత తవ్వడం (15 సెం.మీ లోతు)",
                    description="పార లేదా గునపంతో 15 సెం.మీ (సుమారు 6 అంగుళాలు) లోతు వరకు 'V' ఆకారంలో గుంత తవ్వండి. తోట పంటలకైతే 30 నుండి 60 సెం.మీ లోతు తీసుకోవాలి.",
                    icon="content_cut",
                    tips=["సాధారణ పంటలకు 15 సెం.మీ చాలు", "పండ్ల తోటలకు 30 నుండి 60 సెం.మీ లోతు అవసరం"]
                ),
                SoilGuideStep(
                    stepNumber=4,
                    title="మట్టి పొరను సేకరించడం",
                    description="'V' ఆకారపు గుంత పక్క అంచు నుండి పైనుండి కిందవరకు 1-2 సెం.మీ మందం ఉండేలా మట్టి పొరను గీకి ప్లాస్టిక్ బకెట్ లో వేయండి.",
                    icon="layers",
                    tips=["ఇనుప బకెట్ కాకుండా శుభ్రమైన ప్లాస్టిక్ బకెట్ వాడండి"]
                ),
                SoilGuideStep(
                    stepNumber=5,
                    title="కలపడం & పావు భాగం చేయడం (Quartering)",
                    description="అన్ని ప్రదేశాల నుండి సేకరించిన మట్టిని బాగా కలిపి ఒక శుభ్రమైన ప్లాస్టిక్ షీట్ పై గుండ్రంగా పరచండి. నాలుగు భాగాలు చేసి ఎదురెదురు రెండు భాగాలను తీసివేసి, మిగిలిన భాగాన్ని మళ్ళీ కలపండి. అర కిలో మట్టి మిగిలేవరకు ఇలా చేయండి.",
                    icon="pie_chart",
                    tips=["తుది నమూనా అర కిలో (500 గ్రాములు) సరిపోతుంది", "పెద్ద రాళ్ళు, వేర్లు ఏరివేయండి"]
                ),
                SoilGuideStep(
                    stepNumber=6,
                    title="నీడలో ఆరబెట్టడం & లేబుల్ వేయడం",
                    description="సేకరించిన మట్టిని నీడలో శుభ్రమైన కాగితం లేదా ప్లాస్టిక్ పై ఆరబెట్టండి (ఎండలో పెట్టవద్దు). బట్ట లేదా పాలిథీన్ సంచిలో పోసి రైతు పేరు, సర్వే నంబర్, పంట వివరాలు రాసి లేబుల్ అతికించండి.",
                    icon="label",
                    tips=["నేరుగా ఎండలో లేదా పొయ్యి దగ్గర ఆరబెట్టవద్దు", "రైతు భరోసా కేంద్రం (RBK) లేదా వ్యవసాయ శాఖ ల్యాబ్‌కు పంపించండి"]
                ),
            ],
            dosAndDonts={
                "dos": [
                    "ఎకరాకు 8-10 వేర్వేరు ప్రదేశాల నుండి నమూనాలు తీయండి",
                    "ప్లాస్టిక్ లేదా బట్ట సంచులను మాత్రమే వాడండి",
                    "నమూనాపై వివరాల చీటీ తప్పనిసరిగా ఉంచండి",
                    "ప్రతి 2-3 సంవత్సరాలకు ఒకసారి మట్టి పరీక్ష చేయించండి"
                ],
                "donts": [
                    "ఎరువులు వేసిన వెంటనే నమూనా తీయవద్దు",
                    "ఎరువుల సంచులను లేదా రసాయనాల సంచులను మట్టి నింపడానికి వాడవద్దు",
                    "నీరు నిలిచిన తేమ ప్రదేశాల్లో నమూనాలు తీయవద్దు",
                    "ఎండలో నేరుగా ఆరబెట్టవద్దు"
                ]
            }
        )

    if lang == "ta":
        return SoilSamplingGuideResponse(
            title="மண் மாதிரி சேகரிப்பு முழுமையான வழிகாட்டி",
            importance="மண் பரிசோதனை மூலம் உங்கள் நிலத்தின் pH அளவு, தழை, மணி, சாம்பல் சத்துக்கள் மற்றும் நுண்ணூட்டச்சத்துக்களை அறிந்து சரியான உரங்களை பயன்படுத்தி செலவை குறைக்கலாம்.",
            bestTiming="விதைப்பதற்கு 1 மாதத்திற்கு முன்போ அல்லது அறுவடை முடிந்த உடனோ மாதிரிகள் சேகரிக்க வேண்டும். அதிக மழை அல்லது உரமிட்ட உடனே எடுக்கக்கூடாது.",
            steps=[
                SoilGuideStep(
                    stepNumber=1,
                    title="மாதிரி எடுக்கும் இடங்களை தேர்வு செய்தல் (Zig-Zag முறை)",
                    description="வயல் முழுவதும் ஒரே நேர்கோட்டில் எடுக்காமல் 'ஜிக்-ஜாக்' முறையில் நடந்து ஏக்கருக்கு 8 முதல் 10 இடங்களில் புள்ளிகளை தேர்வு செய்யவும். வரப்புகள், மரங்களின் நிழல், வாய்க்கால்களை தவிர்க்கவும்.",
                    icon="map",
                    tips=["வரப்புகளில் இருந்து குறைந்தது 2-3 மீட்டர் தூரம் தள்ளி இருக்க வேண்டும்", "மரங்களின் நிழல் மற்றும் எரு குவியல்களுக்கு அருகில் எடுக்க வேண்டாம்"]
                ),
                SoilGuideStep(
                    stepNumber=2,
                    title="மேற்பரப்பை சுத்தம் செய்தல்",
                    description="தேர்வு செய்த இடத்தில் உள்ள காய்ந்த இலைகள், புல் மற்றும் குப்பைகளை கத்தியால் அல்லது மண்வெட்டியால் லேசாக அகற்றவும்.",
                    icon="cleaning_services",
                    tips=["மேல்புறத்தில் 1-2 செ.மீ குப்பைகளை மட்டும் அகற்றவும், மண்ணை தோண்ட வேண்டாம்"]
                ),
                SoilGuideStep(
                    stepNumber=3,
                    title="'V' வடிவ குழி தோண்டுதல் (15 செ.மீ ஆழம்)",
                    description="மண்வெட்டியால் 15 செ.மீ (சுமார் 6 அங்குலம்) ஆழத்திற்கு 'V' வடிவில் குழி தோண்டவும். பழத்தோட்ட பயிர்களுக்கு 30 முதல் 60 செ.மீ ஆழம் எடுக்க வேண்டும்.",
                    icon="content_cut",
                    tips=["நெல், பருத்தி, காய்கறி பயிர்களுக்கு 15 செ.மீ போதுமானது", "பழ மரங்களுக்கு 30 முதல் 60 செ.மீ ஆழம் தேவை"]
                ),
                SoilGuideStep(
                    stepNumber=4,
                    title="மண் படலத்தை சேகரித்தல்",
                    description="'V' வடிவ குழியின் ஒரு பக்க சுவரிலிருந்து மேலிருந்து கீழ் வரை 1-2 செ.மீ தடிமனில் மண் அடுக்கை சீவி சுத்தமான பிளாஸ்டிக் வாளியில் போடவும்.",
                    icon="layers",
                    tips=["இரும்பு சட்டிக்கு பதிலாக சுத்தமான பிளாஸ்டிக் வாளி பயன்படுத்தவும்"]
                ),
                SoilGuideStep(
                    stepNumber=5,
                    title="நன்கு கலக்குதல் & கால் பகுதி முறை (Quartering)",
                    description="அனைத்து இடங்களில் எடுத்த மண்ணை நன்கு கலந்து சுத்தமான பிளாஸ்டிக் தாளிலோ அல்லது துணியிலோ வட்டமாக பரப்பவும். நான்காக பிரித்து எதிர் இரண்டு பகுதிகளை நீக்கிவிட்டு, மீதியை மீண்டும் கலக்கவும். 500 கிராம் மிஞ்சும் வரை இதை செய்யவும்.",
                    icon="pie_chart",
                    tips=["இறுதி மாதிரி அரை கிலோ (500 கிராம்) இருக்க வேண்டும்", "கற்கள், வேர்களை அகற்றிவிடவும்"]
                ),
                SoilGuideStep(
                    stepNumber=6,
                    title="நிழலில் உலர்த்துதல் & விவர அட்டை",
                    description="மண்ணை நிழலில் உலர்த்தவும் (வெயிலில் வைக்கக்கூடாது). சுத்தமான துணி அல்லது பாலித்தீன் பையில் போட்டு விவசாயி பெயர், புல எண், பயிர் விவரம் எழுதி லேபிள் ஒட்டவும்.",
                    icon="label",
                    tips=["நேரடி வெயிலில் உலர்த்த வேண்டாம்", "அருகிலுள்ள மண் பரிசோதனை ஆய்வகம் அல்லது உழவர் மையத்திற்கு அனுப்பவும்"]
                ),
            ],
            dosAndDonts={
                "dos": [
                    "ஏக்கருக்கு 8-10 இடங்களில் மாதிரி எடுக்கவும்",
                    "சுத்தமான பிளாஸ்டிக் வாளி மற்றும் பையை பயன்படுத்தவும்",
                    "விவர சீட்டை பையுடன் இணைக்கவும்",
                    "2-3 ஆண்டுகளுக்கு ஒருமுறை மண் பரிசோதனை செய்யவும்"
                ],
                "donts": [
                    "உரமிட்ட உடனே மண் மாதிரி எடுக்கக்கூடாது",
                    "பழைய உர அல்லது பூச்சிக்கொல்லி பைகளை பயன்படுத்த வேண்டாம்",
                    "நீர் தேங்கிய ஈர நிலங்களில் மாதிரி எடுக்க வேண்டாம்",
                    "நேரடி வெயிலில் உலர்த்த வேண்டாம்"
                ]
            }
        )

    if lang == "hi":
        return SoilSamplingGuideResponse(
            title="मृदा नमूना संग्रह संपूर्ण मार्गदर्शिका",
            importance="मृदा परीक्षण से आपकी मिट्टी में पोषक तत्वों, pH मान और जैविक कार्बन का सही स्तर पता चलता है, जिससे संतुलित खाद डालकर उत्पादन बढ़ाया और लागत घटाई जा सकती है।",
            bestTiming="बुवाई से 1 महीने पहले या फसल कटाई के तुरंत बाद नमूना लें। भारी बारिश या खाद डालने के तुरंत बाद नमूना न लें।",
            steps=[
                SoilGuideStep(
                    stepNumber=1,
                    title="नमूना स्थलों का चयन (ज़िग-ज़ैग विधि)",
                    description="खेत में सीधे न चलकर 'ज़िग-ज़ैग' (V आकार) में घूमें और प्रति एकड़ 8 से 10 स्थानों का चयन करें। मेड़ों, छायादार पेड़ों और नालियों के पास से नमूना न लें।",
                    icon="map",
                    tips=["मेड़ से कम से कम 2-3 मीटर की दूरी रखें", "खाद के गड्ढे या पेड़ों के नीचे से नमूना न लें"]
                ),
                SoilGuideStep(
                    stepNumber=2,
                    title="सतह की सफाई",
                    description="चिह्नित स्थान से घास-फूस, खरपतवार और सूखे कचरे को खुरपी से धीरे से हटा दें।",
                    icon="cleaning_services",
                    tips=["केवल 1-2 सेमी ऊपरी कचरा हटाएं, मिट्टी को न खोदें"]
                ),
                SoilGuideStep(
                    stepNumber=3,
                    title="'V' आकार का गड्ढा खोदना (15 सेमी गहराई)",
                    description="खुरपी या फावड़े से 15 सेमी (लगभग 6 इंच) गहरा 'V' आकार का गड्ढा बनाएं। बागवानी फसलों के लिए 30 से 60 सेमी गहरा गड्ढा खोदें।",
                    icon="content_cut",
                    tips=["अनाज, कपास और सब्जियों के लिए 15 सेमी गहराई पर्याप्त है", "बागवानी के लिए 30-60 सेमी गहराई आवश्यक है"]
                ),
                SoilGuideStep(
                    stepNumber=4,
                    title="मिट्टी की परत खुरचना",
                    description="'V' आकार के गड्ढे की दीवार से ऊपर से नीचे तक 1-2 सेमी मोटी मिट्टी की परत खुरचकर प्लास्टिक की बाल्टी में डालें।",
                    icon="layers",
                    tips=["लोहे के बर्तन के बजाय साफ प्लास्टिक बाल्टी का उपयोग करें"]
                ),
                SoilGuideStep(
                    stepNumber=5,
                    title="मिश्रण और चौथाईकरण (Quartering विधि)",
                    description="सभी स्थानों की मिट्टी को अच्छी तरह मिलाएं और साफ चादर पर गोल फैलाएं। इसे 4 हिस्सों में बांटकर आमने-सामने के दो हिस्से हटा दें। जब तक 500 ग्राम मिट्टी न बचे, यह प्रक्रिया दोहराएं।",
                    icon="pie_chart",
                    tips=["अंतिम नमूना आधा किलो (500 ग्राम) होना चाहिए", "कंकड़, पत्थर और जड़ें निकाल दें"]
                ),
                SoilGuideStep(
                    stepNumber=6,
                    title="छाया में सुखाना और लेबल लगाना",
                    description="नमूने को छाया में सुखाएं (धूप में न रखें)। कपड़े या पॉलीथीन की थैली में भरकर किसान का नाम, खसरा नंबर और फसल की जानकारी लिखकर लेबल लगाएं।",
                    icon="label",
                    tips=["धूप में या आग के पास न सुखाएं", "निकटतम मृदा परीक्षण प्रयोगशाला या कृषि केंद्र में जमा करें"]
                ),
            ],
            dosAndDonts={
                "dos": [
                    "प्रति एकड़ 8-10 अलग-अलग स्थानों से नमूना लें",
                    "साफ प्लास्टिक या कपड़े की थैली का ही उपयोग करें",
                    "नमूने पर पूरी जानकारी वाला लेबल अवश्य लगाएं",
                    "प्रत्येक 2-3 वर्ष में मिट्टी की जांच जरूर करवाएं"
                ],
                "donts": [
                    "खाद या कीटनाशक डालने के तुरंत बाद नमूना न लें",
                    "खाद या यूरिया की पुरानी बोरी में मिट्टी न भरें",
                    "जलभराव वाले दलदली स्थान से नमूना न लें",
                    "धूप में सीधे न सुखाएं"
                ]
            }
        )

    if lang == "kn":
        return SoilSamplingGuideResponse(
            title="ಮಣ್ಣಿನ ಮಾದರಿ ಸಂಗ್ರಹಣೆ ಸಮಗ್ರ ಮಾರ್ಗದರ್ಶಿ",
            importance="ಮಣ್ಣು ಪರೀಕ್ಷೆಯ ಮೂಲಕ ಪೋಷಕಾಂಶಗಳು, pH ಮೌಲ್ಯ ಮತ್ತು ಸಾವಯವ ಇಂಗಾಲವನ್ನು ತಿಳಿದುಕೊಂಡು ಸಮತೋಲಿತ ಗೊಬ್ಬರ ಬಳಸಿ ವೆಚ್ಚವನ್ನು ಕಡಿಮೆ ಮಾಡಬಹುದು.",
            bestTiming="ಬಿತ್ತನೆಗೆ 1 ತಿಂಗಳ ಮೊದಲು ಅಥವಾ ಬೆಳೆ ಕೊಯ್ಲಿನ ನಂತರ ಮಾದರಿಗಳನ್ನು ಸಂಗ್ರಹಿಸಿ. ಭಾರಿ ಮಳೆ ಅಥವಾ ಗೊಬ್ಬರ ಹಾಕಿದ ತಕ್ಷಣ ಸಂಗ್ರಹಿಸಬೇಡಿ.",
            steps=[
                SoilGuideStep(
                    stepNumber=1,
                    title="ಮಾದರಿ ಸ್ಥಳಗಳನ್ನು ಗುರುತಿಸುವುದು (ಜಿಗ್-ಜಾಗ್ ವಿಧಾನ)",
                    description="ಜಮೀನಿನಲ್ಲಿ ನೇರವಾಗಿ ನಡೆಯದೆ ಜಿಗ್-ಜಾಗ್ (V ಆಕಾರ) ರೀತಿಯಲ್ಲಿ ಸಂಚರಿಸಿ ಪ್ರತಿ ಎಕರೆಗೆ 8 ರಿಂದ 10 ಸ್ಥಳಗಳನ್ನು ಗುರುತಿಸಿ. ಬದುಗಳು, ಕಾಲುವೆ ಮತ್ತು ಮರದ ನೆರಳನ್ನು ತಪ್ಪಿಸಿ.",
                    icon="map",
                    tips=["ಬದುಗಳಿಂದ ಕನಿಷ್ಠ 2-3 ಮೀಟರ್ ದೂರವಿರಲಿ", "ಗೊಬ್ಬರದ ಗುಂಡಿ ಅಥವಾ ಮರದ ನೆರಳಿನಲ್ಲಿ ಸಂಗ್ರಹಿಸಬೇಡಿ"]
                ),
                SoilGuideStep(
                    stepNumber=2,
                    title="ಮೇಲ್ಮೈ ಸ್ವಚ್ಛಗೊಳಿಸುವಿಕೆ",
                    description="ಆಯ್ಕೆಮಾಡಿದ ಸ್ಥಳದಲ್ಲಿ ಒಣ ಎಲೆಗಳು, ಹುಲ್ಲು ಮತ್ತು ಕಸವನ್ನು ಕುಡುಗೋಲಿನಿಂದ ನಿಧಾನವಾಗಿ ತೆಗೆದುಹಾಕಿ.",
                    icon="cleaning_services",
                    tips=["ಕೇವಲ ಮೇಲಿನ 1-2 ಸೆಂ.ಮೀ ಕಸ ತೆಗೆಯಿರಿ, ಮಣ್ಣನ್ನು ಅಗೆಯಬೇಡಿ"]
                ),
                SoilGuideStep(
                    stepNumber=3,
                    title="'V' ಆಕಾರದ ಗುಂಡಿ ತೋಡುವುದು (15 ಸೆಂ.ಮೀ ಆಳ)",
                    description="ಪಿಕಾಸಿ ಅಥವಾ ಹಾರೆ ಬಳಸಿ 15 ಸೆಂ.ಮೀ (ಸುಮಾರು 6 ಇಂಚು) ಆಳದ 'V' ಆಕಾರದ ಗುಂಡಿ ಮಾಡಿ. ತೋಟಗಾರಿಕೆ ಬೆಳೆಗಳಿಗೆ 30 ರಿಂದ 60 ಸೆಂ.ಮೀ ಆಳ ಬೇಕು.",
                    icon="content_cut",
                    tips=["ಏಕದಳ, ಹತ್ತಿ, ತರಕಾರಿಗಳಿಗೆ 15 ಸೆಂ.ಮೀ ಆಳ ಸಾಕು", "ಹಣ್ಣಿನ ತೋಟಗಳಿಗೆ 30-60 ಸೆಂ.ಮೀ ಅಗತ್ಯ"]
                ),
                SoilGuideStep(
                    stepNumber=4,
                    title="ಮಣ್ಣಿನ ಪದರವನ್ನು ಸಂಗ್ರಹಿಸುವುದು",
                    description="'V' ಆಕಾರದ ಗುಂಡಿಯ ಬದಿಯಿಂದ ಮೇಲಿನಿಂದ ಕೆಳಕ್ಕೆ 1-2 ಸೆಂ.ಮೀ ದಪ್ಪದ ಮಣ್ಣಿನ ಪದರವನ್ನು ಕೆತ್ತಿ ಪ್ಲಾಸ್ಟಿಕ್ ಬಕೆಟ್‌ಗೆ ಹಾಕಿ.",
                    icon="layers",
                    tips=["ಕಬ್ಬಿಣದ ಪಾತ್ರೆ ಬದಲು ಸ್ವಚ್ಛವಾದ ಪ್ಲಾಸ್ಟಿಕ್ ಬಕೆಟ್ ಬಳಸಿ"]
                ),
                SoilGuideStep(
                    stepNumber=5,
                    title="ಮಿಶ್ರಣ ಮತ್ತು ನಾಲ್ಕು ಭಾಗ ಮಾಡುವ ವಿಧಾನ (Quartering)",
                    description="ಎಲ್ಲಾ ಕಡೆಯ ಮಣ್ಣನ್ನು ಚೆನ್ನಾಗಿ ಬೆರೆಸಿ ಸ್ವಚ್ಛ ಹಾಳೆಯ ಮೇಲೆ ವೃತ್ತಾಕಾರದಲ್ಲಿ ಹರಡಿ. 4 ಭಾಗ ಮಾಡಿ ಎದುರು-ಬದುರಿನ ಎರಡು ಭಾಗಗಳನ್ನು ತೆಗೆಯಿರಿ. 500 ಗ್ರಾಂ ಉಳಿಯುವವರೆಗೆ ಪುನರಾವರ್ತಿಸಿ.",
                    icon="pie_chart",
                    tips=["ಅಂತಿಮ ಮಾದರಿ 500 ಗ್ರಾಂ (ಅರ್ಧ ಕೆಜಿ) ಇರಬೇಕು", "ಕಲ್ಲು ಮತ್ತು ಬೇರುಗಳನ್ನು ತೆಗೆದುಹಾಕಿ"]
                ),
                SoilGuideStep(
                    stepNumber=6,
                    title="ನೆರಳಿನಲ್ಲಿ ಒಣಗಿಸುವುದು ಮತ್ತು ಲೇಬಲ್ ಮಾಡುವುದು",
                    description="ಮಾದರಿಯನ್ನು ನೆರಳಿನಲ್ಲಿ ಒಣಗಿಸಿ. ಬಟ್ಟೆ ಅಥವಾ ಪಾಲಿಥಿನ್ ಚೀಲದಲ್ಲಿ ತುಂಬಿ ರೈತರ ಹೆಸರು, ಸರ್ವೆ ನಂಬರ್, ಬೆಳೆ ವಿವರ ಬರೆದು ಪ್ರಯೋಗಾಲಯಕ್ಕೆ ಕಳುಹಿಸಿ.",
                    icon="label",
                    tips=["ಬಿಸಿಲಿನಲ್ಲಿ ಒಣಗಿಸಬೇಡಿ", "ಹತ್ತಿರದ ಮಣ್ಣು ಪರೀಕ್ಷಾ ಕೇಂದ್ರಕ್ಕೆ ಸಲ್ಲಿಸಿ"]
                ),
            ],
            dosAndDonts={
                "dos": [
                    "ಪ್ರತಿ ಎಕರೆಗೆ 8-10 ಸ್ಥಳಗಳಿಂದ ಮಾದರಿ ಸಂಗ್ರಹಿಸಿ",
                    "ಪ್ಲಾಸ್ಟಿಕ್ ಬಕೆಟ್ ಮತ್ತು ಸ್ವಚ್ಛ ಚೀಲ ಬಳಸಿ",
                    "ಮಾದರಿಯ ಜೊತೆ ವಿವರವಾದ ಚೀಟಿಯನ್ನು ಕಡ್ಡಾಯವಾಗಿ ಇರಿಸಿ",
                    "ಪ್ರತಿ 2-3 ವರ್ಷಗಳಿಗೊಮ್ಮೆ ಮಣ್ಣು ಪರೀಕ್ಷೆ ಮಾಡಿಸಿ"
                ],
                "donts": [
                    "ಗೊಬ್ಬರ ಅಥವಾ ಕೀಟನಾಶಕ ಹಾಕಿದ ತಕ್ಷಣ ಮಾದರಿ ತೆಗೆಯಬೇಡಿ",
                    "ಹಳೆಯ ರಸಗೊಬ್ಬರದ ಚೀಲಗಳನ್ನು ಮಣ್ಣು ತುಂಬಲು ಬಳಸಬೇಡಿ",
                    "ಜವಳು ಅಥವಾ ನೀರು ನಿಂತ ಸ್ಥಳದಿಂದ ಮಾದರಿ ಸಂಗ್ರಹಿಸಬೇಡಿ",
                    "ನೇರ ಬಿಸಿಲಿನಲ್ಲಿ ಒಣಗಿಸಬೇಡಿ"
                ]
            }
        )

    if lang == "ml":
        return SoilSamplingGuideResponse(
            title="മണ്ണ് സാമ്പിൾ ശേഖരണ സമ്പൂർണ്ണ മാർഗ്ഗരേഖ",
            importance="മണ്ണ് പരിശോധനയിലൂടെ പോഷകങ്ങൾ, pH മൂല്യം, ജൈവ കാർബൺ എന്നിവ മനസ്സിലാക്കി കൃത്യമായ അളവിൽ വളം പ്രയോഗിച്ച് ചെലവ് കുറയ്ക്കാം.",
            bestTiming="വിത്ത് വിതയ്ക്കുന്നതിന് 1 മാസം മുമ്പോ വിളവെടുപ്പിന് ശേഷമോ സാമ്പിൾ എടുക്കുക.",
            steps=[
                SoilGuideStep(stepNumber=1, title="സാമ്പിൾ എടുക്കുന്ന സ്ഥലങ്ങൾ കണ്ടെത്തുക (സിഗ്-സാഗ് രീതി)", description="പാടത്ത് നേർരേഖയിലല്ലാതെ സിഗ്-സാഗ് രീതിയിൽ നടന്ന് ഏക്കറിന് 8-10 സ്ഥലങ്ങൾ തിരഞ്ഞെടുക്കുക. വരമ്പുകളും തണലുള്ള മരച്ചുവടുകളും ഒഴിവാക്കുക.", icon="map", tips=["വരമ്പുകളിൽ നിന്ന് 2-3 മീറ്റർ മാറുക", "വളം കുഴികൾക്ക് സമീപം സാമ്പിൾ എടുക്കരുത്"]),
                SoilGuideStep(stepNumber=2, title="ഉപരിതലം വൃത്തിയാക്കൽ", description="തിരഞ്ഞെടുത്ത സ്ഥലത്തെ പുല്ലും കരിയിലകളും ചെടികളും ശ്രദ്ധയോടെ മാറ്റുക.", icon="cleaning_services", tips=["മേൽമണ്ണ് മാറ്റാതെ മാലിന്യങ്ങൾ മാത്രം നീക്കുക"]),
                SoilGuideStep(stepNumber=3, title="'V' ആകൃതിയിൽ കുഴിയെടുക്കൽ (15 സെ.മീ)", description="കൈക്കോട്ട് ഉപയോഗിച്ച് 15 സെ.മീ ആഴത്തിൽ 'V' ആകൃതിയിൽ കുഴിയെടുക്കുക. തോട്ടവിളകൾക്ക് 30-60 സെ.മീ ആഴം വേണം.", icon="content_cut", tips=["നെല്ല്, പച്ചക്കറികൾക്ക് 15 സെ.മീ ആഴം അനുയോജ്യമാണ്"]),
                SoilGuideStep(stepNumber=4, title="മണ്ണ് പാളി ചുരണ്ടി എടുക്കൽ", description="'V' കുഴിയുടെ വശങ്ങളിൽ നിന്ന് മുകളിൽ നിന്ന് താഴേക്ക് 1-2 സെ.മീ കനത്തിൽ മണ്ണ് ചുരണ്ടി പ്ലാസ്റ്റിക് പാത്രത്തിൽ ശേഖരിക്കുക.", icon="layers", tips=["വൃത്തിയുള്ള പ്ലാസ്റ്റിക് പാത്രം ഉപയോഗിക്കുക"]),
                SoilGuideStep(stepNumber=5, title="നന്നായി ഇളക്കി നാലായി ഭാഗിക്കൽ (Quartering)", description="ശേഖരിച്ച മണ്ണ് നന്നായി ഇളക്കി വൃത്തിയുള്ള ഷീറ്റിൽ വട്ടത്തിൽ നിരത്തുക. 4 ഭാഗങ്ങളാക്കി എതിർവശങ്ങളിലെ 2 ഭാഗങ്ങൾ ഒഴിവാക്കുക. 500 ഗ്രാം ആകുന്നത് വരെ തുടരുക.", icon="pie_chart", tips=["അവസാന സാമ്പിൾ 500 ഗ്രാം മതിയാകും", "കല്ലുകളും വേരുകളും മാറ്റുക"]),
                SoilGuideStep(stepNumber=6, title="തണലിൽ ഉണക്കലും ലേബൽ ഒട്ടിക്കലും", description="മണ്ണ് തണലിൽ ഉണക്കുക. തുണിസഞ്ചിയിലാക്കി കർഷകന്റെ പേര്, സർവേ നമ്പർ, വിള എന്നിവ രേഖപ്പെടുത്തി ലാബിൽ എത്തിക്കുക.", icon="label", tips=["വെയിലിൽ വെച്ച് ഉണക്കരുത്", "അടുത്തുള്ള മണ്ണ് പരിശോധനാ കേന്ദ്രത്തിൽ നൽകുക"]),
            ],
            dosAndDonts={"dos": ["ഏക്കറിന് 8-10 സ്ഥലങ്ങളിൽ നിന്ന് സാമ്പിൾ എടുക്കുക", "പ്ലാസ്റ്റിക് പാത്രവും സഞ്ചിയും ഉപയോഗിക്കുക"], "donts": ["രാസവളം ഇട്ട ഉടനെ സാമ്പിൾ എടുക്കരുത്", "നേരിട്ട് വെയിലിൽ ഉണക്കരുത്"]}
        )

    if lang == "mr":
        return SoilSamplingGuideResponse(
            title="माती नमुना संकलन संपूर्ण मार्गदर्शिका",
            importance="माती परीक्षणामुळे जमिनीतील अन्नद्रव्ये, सामू (pH) आणि सेंद्रिय कर्ब समजून खतांचा समतोल वापर करता येतो व खर्च कमी होतो.",
            bestTiming="पेरणीच्या १ महिना आधी किंवा पीक काढणीनंतर लगेच नमुने घ्यावेत.",
            steps=[
                SoilGuideStep(stepNumber=1, title="नमुना जागांची निवड (झिग-झॅग पद्धत)", description="शेतभर झिग-झॅग (V आकारात) फिरून एकरी ८ ते १० ठिकाणे निवडा. बांध, चर आणि झाडांची सावली टाळा.", icon="map", tips=["बांधापासून २-३ मीटर लांब नमुना घ्या", "खताच्या खड्ड्यांजवळ नमुना घेऊ नका"]),
                SoilGuideStep(stepNumber=2, title="पृष्ठभाग स्वच्छ करणे", description="निवडलेल्या जागेवरील गवत, कचरा व पालापाचोळा खुरप्याने हलकेच बाजूला करा.", icon="cleaning_services", tips=["फक्त वरचा कचरा काढा, माती खणू नका"]),
                SoilGuideStep(stepNumber=3, title="'V' आकाराचा खड्डा करणे (१५ सेमी खोली)", description="खुरपे किंवा फावड्याने १५ सेमी खोलीचा 'V' आकाराचा खड्डा करा. बागायती फळझाडांसाठी ३० ते ६० सेमी खोली ठेवावी.", icon="content_cut", tips=["धान्य, कापूस, भाज्यांसाठी १५ सेमी खोली पुरेशी आहे"]),
                SoilGuideStep(stepNumber=4, title="मातीचा थर खरवडणे", description="'V' खड्ड्याच्या एका बाजूने वरपासून खालपर्यंत १-२ सेमी जाडीचा थर खरवडून प्लास्टिक बादलीत जमा करा.", icon="layers", tips=["लोखंडी भांड्याऐवजी स्वच्छ प्लास्टिक बादली वापरा"]),
                SoilGuideStep(stepNumber=5, title="मिश्रण आणि चार भाग करण्याची पद्धत (Quartering)", description="सर्व माती एकत्र करून स्वच्छ कापडावर पसरवा. ४ भाग करून समोरासमोरील २ भाग काढून टाका. ५०० ग्रॅम माती उरेपर्यंत ही प्रक्रिया करा.", icon="pie_chart", tips=["अंतिम नमुना ५०० ग्रॅम असावा", "दगड व मुळे काढून टाका"]),
                SoilGuideStep(stepNumber=6, title="सावलीजवळ वाळवणे आणि लेबल लावणे", description="माती सावलीत वाळवा. कापडी किंवा पॉलिथिन पिशवीत भरून शेतकऱ्याचे नाव, गट नंबर, पीक लिहून प्रयोगशाळेत पाठवा.", icon="label", tips=["उन्हात किंवा आचेवर वाळवू नका", "नजीकच्या माती परीक्षण प्रयोगशाळेत जमा करा"]),
            ],
            dosAndDonts={"dos": ["एकरी ८-१० वेगवेगळ्या ठिकाणांवरून नमुने घ्या", "स्वच्छ पिशवी वापरा"], "donts": ["खत टाकल्यावर लगेच नमुना घेऊ नका", "उन्हात सुकवू नका"]}
        )

    if lang == "bn":
        return SoilSamplingGuideResponse(
            title="মাটির নমুনা সংগ্রহ সম্পূর্ণ নির্দেশিকা",
            importance="মাটি পরীক্ষার মাধ্যমে জমিতে থাকা পুষ্টি উপাদান, pH মাত্রা এবং জৈব কার্বন জেনে সুষম সার প্রয়োগ করে খরচ কমানো সম্ভব।",
            bestTiming="বপনের ১ মাস আগে বা ফসল কাটার পরপরই নমুনা সংগ্রহ করুন।",
            steps=[
                SoilGuideStep(stepNumber=1, title="নমুনার স্থান নির্বাচন (জিগ-জ্যাগ পদ্ধতি)", description="জমিতে সোজা না হেঁটে জিগ-জ্যাগ পদ্ধতিতে ঘুরে প্রতি একরে ৮ থেকে ১০টি স্থান চিহ্নিত করুন। আইল ও গাছের ছায়া বাদ দিন।", icon="map", tips=["আইল থেকে ২-৩ মিটার দূরে নমুনা নিন", "সার গর্তের কাছে নমুনা নেবেন না"]),
                SoilGuideStep(stepNumber=2, title="উপরিভাগ পরিষ্কার করা", description="চিহ্নিত স্থানের ঘাস, শুকনো পাতা ও ময়লা হালকাভাবে সরিয়ে ফেলুন।", icon="cleaning_services", tips=["শুধু ওপরের ময়লা সরান, মাটি খুঁড়বেন না"]),
                SoilGuideStep(stepNumber=3, title="'V' আকৃতির গর্ত তৈরি (১৫ সেমি গভীর)", description="কোদাল বা খুরপি দিয়ে ১৫ সেমি গভীর 'V' আকৃতির গর্ত করুন। ফলের বাগানের জন্য ৩০-৬০ সেমি গভীরতা দরকার।", icon="content_cut", tips=["ধান, পাট ও সবজির জন্য ১৫ সেমি গভীরতা যথেষ্ট"]),
                SoilGuideStep(stepNumber=4, title="মাটির স্তর চাঁছা", description="'V' আকৃতির গর্তের এক ধার থেকে ওপর থেকে নিচ পর্যন্ত ১-২ সেমি পুরু মাটির স্তর কেটে বালতিতে নিন।", icon="layers", tips=["পরিষ্কার প্লাস্টিক বালতি ব্যবহার করুন"]),
                SoilGuideStep(stepNumber=5, title="মিশ্রণ ও চার ভাগে ভাগ (Quartering)", description="সমস্ত মাটি ভালোভাবে মিশিয়ে পরিষ্কার কাগজে গোল করে ছড়িয়ে দিন। ৪ ভাগ করে মুখোমুখি ২ ভাগ বাদ দিন। ৫০০ গ্রাম অবশিষ্ট থাকা পর্যন্ত পুনরাবৃত্তি করুন।", icon="pie_chart", tips=["চূড়ান্ত নমুনা ৫০০ গ্রাম হতে হবে", "পাথর ও শিকড় সরিয়ে ফেলুন"]),
                SoilGuideStep(stepNumber=6, title="ছায়ায় শুকানো এবং লেবেল লাগানো", description="মাটি ছায়ায় শুকিয়ে নিন। পরিষ্কার কাপড়ের বা পলিথিন থলিতে ভরে কৃষকের নাম, দাগ নম্বর লিখে ল্যাবে পাঠান।", icon="label", tips=["রোদে শুকাবেন না", "নিকটস্থ মৃত্তিকা পরীক্ষা গবেষণাগারে জমা দিন"]),
            ],
            dosAndDonts={"dos": ["প্রতি একরে ৮-১০টি জায়গা থেকে নমুনা নিন", "পরিষ্কার থলি ব্যবহার করুন"], "donts": ["সার দেওয়ার পরপরই নমুনা নেবেন না", "রোদে শুকাবেন না"]}
        )

    if lang == "gu":
        return SoilSamplingGuideResponse(
            title="જમીન નમૂના સંગ્રહ સંપૂર્ણ માર્ગદર્શિકા",
            importance="જમીન ચકાસણી દ્વારા પોષક તત્વો, pH મૂલ્ય અને સેન્દ્રિય કાર્બન જાણીને સંતુલિત ખાતર વાપરી ખર્ચ ઘટાડી શકાય છે.",
            bestTiming="વાવણીના ૧ મહિના પહેલાં અથવા પાકની કાપણી પછી તરત જ નમૂનો લેવો.",
            steps=[
                SoilGuideStep(stepNumber=1, title="નમૂના સ્થળોની પસંદગી (ઝિગ-ઝેગ પદ્ધતિ)", description="ખેતરમાં સીધા ન ચાલતાં ઝિગ-ઝેગ રીતે ફરીને એકર દીઠ ૮ થી ૧૦ સ્થળો પસંદ કરો. શેઢા અને ઝાડની છાયા ટાળો.", icon="map", tips=["શેઢાથી ૨-૩ મીટર દૂર રહો", "ખાતરના ખાડા પાસે નમૂનો ન લો"]),
                SoilGuideStep(stepNumber=2, title="સપાટીની સફાઈ", description="પસંદ કરેલ સ્થળ પરથી સૂકાં પાંદડાં, ઘાસ અને કચરો હળવેથી દૂર કરો.", icon="cleaning_services", tips=["ફક્ત ઉપરનો કચરો હટાવો, જમીન ખોદશો નહીં"]),
                SoilGuideStep(stepNumber=3, title="'V' આકારનો ખાડો કરવો (૧૫ સેમી ઊંડાઈ)", description="કોદાળીથી ૧૫ સેમી ઊંડો 'V' આકારનો ખાડો કરો. બાગાયતી પાકો માટે ૩૦-૬૦ સેમી ઊંડાઈ જરૂરી છે.", icon="content_cut", tips=["કપાસ, મગફળી, અનાજ માટે ૧૫ સેમી પૂરતી છે"]),
                SoilGuideStep(stepNumber=4, title="માટીનું સ્તર ઉતારવું", description="'V' ખાડાની બાજુની દીવાલ પરથી ઉપરથી નીચે સુધી ૧-૨ સેમી જાડું માટીનું સ્તર ઉતારી પ્લાસ્ટિક ડોલમાં લો.", icon="layers", tips=["સ્વચ્છ પ્લાસ્ટિકની ડોલ વાપરો"]),
                SoilGuideStep(stepNumber=5, title="મિશ્રણ અને ચાર ભાગ કરવાની રીત (Quartering)", description="બધી માટી બરાબર મિક્સ કરી પ્લાસ્ટિક શીટ પર ગોળ પાથરો. ૪ ભાગ કરી સામસામેના ૨ ભાગ કાઢી નાખો. ૫૦૦ ગ્રામ વધે ત્યાં સુધી કરો.", icon="pie_chart", tips=["આખરી નમૂનો ૫૦૦ ગ્રામ હોવો જોઈએ", "કાંકરા અને મૂળિયાં દૂર કરો"]),
                SoilGuideStep(stepNumber=6, title="છાંયડે સૂકવવું અને લેબલ લગાવવું", description="માટીને છાંયડે સૂકવો. કાપડની થેલીમાં ભરી ખેડૂતનું નામ, સર્વે નંબર, પાકની વિગત લખી લેબમાં મોકલો.", icon="label", tips=["તડકામાં ન સૂકવવી", "નજીકની જમીન પરીક્ષણ લેબોરેટરીમાં જમા કરો"]),
            ],
            dosAndDonts={"dos": ["એકર દીઠ ૮-૧૦ સ્થળોએથી નમૂનો લો", "સ્વચ્છ થેલી વાપરો"], "donts": ["ખાતર આપ્યા પછી તરત નમૂનો ન લો", "તડકામાં ન સૂકવવો"]}
        )

    if lang == "pa":
        return SoilSamplingGuideResponse(
            title="ਮਿੱਟੀ ਪਰਖ ਨਮੂਨਾ ਇਕੱਤਰ ਕਰਨ ਦੀ ਪੂਰੀ ਗਾਈਡ",
            importance="ਮਿੱਟੀ ਪਰਖ ਕਰਵਾਉਣ ਨਾਲ ਖੁਰਾਕੀ ਤੱਤ, pH ਅਤੇ ਜੈਵਿਕ ਕਾਰਬਨ ਦਾ ਪਤਾ ਲੱਗਦਾ ਹੈ ਜਿਸ ਨਾਲ ਸੰਤੁਲਿਤ ਖਾਦ ਪਾ ਕੇ ਖਰਚਾ ਘਟਾਇਆ ਜਾ ਸਕਦਾ ਹੈ।",
            bestTiming="ਬਿਜਾਈ ਤੋਂ 1 ਮਹੀਨਾ ਪਹਿਲਾਂ ਜਾਂ ਫ਼ਸਲ ਦੀ ਕਟਾਈ ਤੋਂ ਤੁਰੰਤ ਬਾਅਦ ਨਮੂਨਾ ਲਵੋ।",
            steps=[
                SoilGuideStep(stepNumber=1, title="ਨਮੂਨੇ ਵਾਲੀਆਂ ਥਾਵਾਂ ਦੀ ਚੋਣ (ਜ਼ਿਗ-ਜ਼ੈਗ ਤਰੀਕਾ)", description="ਖੇਤ ਵਿੱਚ ਸਿੱਧੇ ਨਾ ਚੱਲ ਕੇ ਜ਼ਿਗ-ਜ਼ੈਗ ਤਰੀਕੇ ਨਾਲ ਪ੍ਰਤੀ ਏਕੜ 8 ਤੋਂ 10 ਥਾਵਾਂ ਚੁਣੋ। ਵੱਟਾਂ ਅਤੇ ਦਰੱਖਤਾਂ ਦੀ ਛਾਂ ਛੱਡ ਦਿਓ।", icon="map", tips=["ਵੱਟ ਤੋਂ 2-3 ਮੀਟਰ ਦੂਰੀ ਰੱਖੋ", "ਰੂੜੀ ਦੇ ਢੇਰ ਕੋਲੋਂ ਨਮੂਨਾ ਨਾ ਲਵੋ"]),
                SoilGuideStep(stepNumber=2, title="ਸਤ੍ਹਾ ਦੀ ਸਫ਼ਾਈ", description="ਚੁਣੀ ਹੋਈ ਥਾਂ ਤੋਂ ਸੁੱਕੇ ਪੱਤੇ, ਘਾਹ-ਫੂਸ ਖੁਰਪੀ ਨਾਲ ਹਲਕੇ ਜਿਹੇ ਸਾਫ਼ ਕਰੋ।", icon="cleaning_services", tips=["ਸਿਰਫ਼ ਉੱਪਰਲਾ ਕੂੜਾ ਸਾਫ਼ ਕਰੋ, ਮਿੱਟੀ ਨਾ ਪੁੱਟੋ"]),
                SoilGuideStep(stepNumber=3, title="'V' ਅਕਾਰ ਦਾ ਟੋਆ ਪੁੱਟਣਾ (15 ਸੈਂਟੀਮੀਟਰ ਡੂੰਘਾਈ)", description="ਖੁਰਪੀ ਜਾਂ ਕਹੀ ਨਾਲ 15 ਸੈਂਟੀਮੀਟਰ (6 ਇੰਚ) ਡੂੰਘਾ 'V' ਅਕਾਰ ਦਾ ਟੋਆ ਪੁੱਟੋ। ਬਾਗਾਂ ਲਈ 30-60 ਸੈਂਟੀਮੀਟਰ ਡੂੰਘਾਈ ਚਾਹੀਦੀ ਹੈ।", icon="content_cut", tips=["ਕਣਕ, ਝੋਨਾ, ਨਰਮਾ ਲਈ 15 ਸੈਂਟੀਮੀਟਰ ਕਾਫ਼ੀ ਹੈ"]),
                SoilGuideStep(stepNumber=4, title="ਮਿੱਟੀ ਦੀ ਤਹਿ ਉਤਾਰਨਾ", description="'V' ਟੋਏ ਦੇ ਪਾਸੇ ਤੋਂ ਉੱਪਰ ਤੋਂ ਹੇਠਾਂ ਤੱਕ 1-2 ਸੈਂਟੀਮੀਟਰ ਮੋਟੀ ਮਿੱਟੀ ਦੀ ਪਰਤ ਖੁਰਚ ਕੇ ਪਲਾਸਟਿਕ ਬਾਲਟੀ ਵਿੱਚ ਪਾਓ।", icon="layers", tips=["ਸਾਫ਼ ਪਲਾਸਟਿਕ ਬਾਲਟੀ ਵਰਤੋ"]),
                SoilGuideStep(stepNumber=5, title="ਰਲਾਉਣਾ ਅਤੇ ਚੌਥਾਈ ਵਿਧੀ (Quartering)", description="ਸਾਰੀ ਮਿੱਟੀ ਚੰਗੀ ਤਰ੍ਹਾਂ ਰਲਾ ਕੇ ਸਾਫ਼ ਸ਼ੀਟ 'ਤੇ ਗੋਲ ਫੈਲਾਓ। 4 ਹਿੱਸੇ ਕਰਕੇ ਆਹਮੋ-ਸਾਹਮਣੇ ਦੇ 2 ਹਿੱਸੇ ਹਟਾ ਦਿਓ। 500 ਗ੍ਰਾਮ ਬਚਣ ਤੱਕ ਦੁਹਰਾਓ।", icon="pie_chart", tips=["ਆਖ਼ਰੀ ਨਮੂਨਾ 500 ਗ੍ਰਾਮ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ", "ਰੋੜੇ ਅਤੇ ਜੜ੍ਹਾਂ ਕੱਢ ਦਿਓ"]),
                SoilGuideStep(stepNumber=6, title="ਛਾਂਵੇਂ ਸੁਕਾਉਣਾ ਅਤੇ ਲੇਬਲ ਲਗਾਉਣਾ", description="ਮਿੱਟੀ ਛਾਂਵੇਂ ਸੁਕਾਓ। ਕੱਪੜੇ ਜਾਂ ਲਿਫ਼ਾਫ਼ੇ ਵਿੱਚ ਭਰ ਕੇ ਕਿਸਾਨ ਦਾ ਨਾਮ, ਖਸਰਾ ਨੰਬਰ, ਫ਼ਸਲ ਲਿਖ ਕੇ ਲੈਬ ਭੇਜੋ।", icon="label", tips=["ਧੁੱਪ ਵਿੱਚ ਨਾ ਸੁਕਾਓ", "ਨੇੜਲੀ ਮਿੱਟੀ ਪਰਖ ਲੈਬਾਰਟਰੀ ਵਿੱਚ ਜਮ੍ਹਾਂ ਕਰਵਾਓ"]),
            ],
            dosAndDonts={"dos": ["ਪ੍ਰਤੀ ਏਕੜ 8-10 ਥਾਵਾਂ ਤੋਂ ਨਮੂਨਾ ਲਵੋ", "ਸਾਫ਼ ਥੈਲੀ ਵਰਤੋ"], "donts": ["ਖਾਦ ਪਾਉਣ ਤੋਂ ਤੁਰੰਤ ਬਾਅਦ ਨਮੂਨਾ ਨਾ ਲਵੋ", "ਸਿੱਧੀ ਧੁੱਪ ਵਿੱਚ ਨਾ ਸੁਕਾਓ"]}
        )

    # Default to English
    return SoilSamplingGuideResponse(
        title="Comprehensive Soil Sampling Guide",
        importance="Soil testing helps you assess fertility, pH, organic carbon, and micronutrients so you can apply the exact fertilizer needed, preventing excess cost and soil degradation.",
        bestTiming="Collect samples 1 month before sowing or right after harvest. Never sample right after fertilizer/manure application or heavy waterlogging.",
        steps=[
            SoilGuideStep(
                stepNumber=1,
                title="Identify Sampling Spots (Zig-Zag Pattern)",
                description="Traverse your field in a zig-zag pattern and choose 8 to 10 representative spots per acre. Avoid field boundaries, bunds, irrigation channels, and tree shade.",
                icon="map",
                tips=["Keep at least 2-3 meters away from fences and bunds", "Avoid spots near compost piles or animal shelters"]
            ),
            SoilGuideStep(
                stepNumber=2,
                title="Surface Clearing",
                description="Scrape away surface litter, dry leaves, and weed cover gently without disturbing topsoil.",
                icon="cleaning_services",
                tips=["Remove only the top 1 cm debris, do not excavate soil yet"]
            ),
            SoilGuideStep(
                stepNumber=3,
                title="Dig a V-Shaped Trench (15 cm Depth)",
                description="Using a clean spade or khurpi, dig a 'V'-shaped hole up to 15 cm (6 inches) deep for field crops. For orchard/fruit trees, sample at 30 to 60 cm depth.",
                icon="content_cut",
                tips=["15 cm depth is ideal for paddy, maize, cotton, and vegetables", "30-60 cm depth for orchard trees"]
            ),
            SoilGuideStep(
                stepNumber=4,
                title="Collect Slice of Soil",
                description="Slice a 1-2 cm thick uniform slice of soil from top to bottom along the exposed side of the V-notch into a clean plastic container.",
                icon="layers",
                tips=["Use clean plastic buckets, avoid rusty metal pans"]
            ),
            SoilGuideStep(
                stepNumber=5,
                title="Mix & Quartering Method",
                description="Mix all collected sub-samples thoroughly. Spread into a circular shape, divide into 4 quarters, discard opposite two quarters, and repeat until approximately 500g remains.",
                icon="pie_chart",
                tips=["Target sample weight is 500 grams", "Discard stones, gravel, and roots"]
            ),
            SoilGuideStep(
                stepNumber=6,
                title="Shade Drying & Bagging",
                description="Air-dry the sample in the shade on clean paper. Pack in a clean cloth or polythene bag with a tag showing Farmer Name, Survey Number, Field Name, and Intended Crop.",
                icon="label",
                tips=["Never sun-dry or heat-dry", "Submit to nearest Soil Testing Laboratory or Rythu Bharosa Kendra"]
            ),
        ],
        dosAndDonts={
            "dos": [
                "Take 8-10 composite samples per acre in a zig-zag line",
                "Air dry in shade before bagging",
                "Label bag with farmer name, date, field ID and previous crop",
                "Retest every 2-3 years for soil sustainability"
            ],
            "donts": [
                "Do not sample immediately after fertilizer or pesticide application",
                "Do not use fertilizer or chemical bags to hold the sample",
                "Do not sample from marshy or water-logged corners",
                "Do not dry soil under direct sunlight"
            ]
        }
    )

@router.post("/analyze", response_model=SoilHealthAnalysisResponse)
async def analyze_soil_parameters(data: SoilDataInput):
    """
    AI-powered soil test analysis based on numeric or categorical values entered by the farmer.
    """
    try:
        input_dict = {
            "crop": data.crop or "General Agricultural Crops",
            "soilType": data.soilType or "Unknown",
            "ph": data.ph,
            "nitrogen_kg_ha": data.nitrogen,
            "phosphorus_kg_ha": data.phosphorus,
            "potassium_kg_ha": data.potassium,
            "organicCarbon_percent": data.organicCarbon,
            "electricalConductivity": data.electricalConductivity
        }

        # Analyze using Gemini AI service
        result_str = await ai_service.analyze_soil_data(input_dict, language_code=data.languageId)
        result_json = json.loads(result_str)
        return SoilHealthAnalysisResponse(**result_json)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        print(f"Soil analysis failed: {e}")
        # Return fallback heuristic response if AI is unavailable or offline
        return SoilHealthAnalysisResponse(
            overallHealth="Moderate",
            summary=f"Soil analysis conducted for {data.crop or 'crops'}. Ensure balanced NPK application.",
            phAnalysis=f"pH is {data.ph if data.ph is not None else 'not specified'}. Standard neutral range is 6.5 - 7.5.",
            conditioningRecommendations=[
                "Incorporate 4-5 tonnes/acre of well-rotted Farm Yard Manure (FYM) or vermicompost",
                "Apply gypsum if soil is alkaline (pH > 8.0) or agricultural lime if acidic (pH < 6.0)"
            ],
            fertilizerPlan=[
                "Apply split dose of Nitrogen (Urea) at vegetative and tillering stages",
                "Apply Phosphatic fertilizers (DAP/SSP) as basal dose during sowing",
                "Apply Potash (MOP) during final land preparation or flowering"
            ],
            suitableCrops=[data.crop or "Rice", "Cotton", "Maize", "Chilli", "Pulses"],
            warningNotes="Always get an accredited lab confirmation before applying concentrated micronutrients."
        )

@router.post("/analyze-card-image", response_model=SoilHealthAnalysisResponse)
async def analyze_soil_card_image(
    image: UploadFile = File(...),
    crop: str = Form(None),
    languageId: str = Form("en")
):
    """
    OCR and AI agronomic analysis for uploaded Soil Health Card images.
    """
    try:
        image_data = await image.read()
        if len(image_data) > 10 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Image size exceeds 10MB limit.")

        result_str = await ai_service.analyze_soil_card_image(
            image_data=image_data,
            crop=crop,
            language_code=languageId
        )
        result_json = json.loads(result_str)
        return SoilHealthAnalysisResponse(**result_json)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        print(f"Soil card image analysis failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to analyze soil test report image.")
