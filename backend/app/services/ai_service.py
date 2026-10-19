import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

class AIService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        if self.api_key:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel('gemini-flash-latest')
        else:
            self.model = None

    def _get_language_name(self, language_code: str) -> str:
        lang_map = {
            'en': 'English',
            'te': 'Telugu',
            'hi': 'Hindi',
            'ta': 'Tamil',
            'kn': 'Kannada',
            'ml': 'Malayalam',
            'mr': 'Marathi',
            'bn': 'Bengali',
            'gu': 'Gujarati',
            'pa': 'Punjabi'
        }
        return lang_map.get(language_code, 'English')

    async def generate_chat_response(self, message: str, language_code: str, context: dict = None) -> str:
        if not self.model or self.api_key == "your_gemini_api_key_here":
            raise ValueError("GEMINI_API_KEY environment variable is not set")
            
        language_name = self._get_language_name(language_code)
        
        system_prompt = f"""
        You are RythuMitra AI (రైతుమిత్ర AI), an intelligent, compassionate, and trustworthy farming companion dedicated to empowering Indian farmers (especially in Andhra Pradesh, Telangana, and across India).

        CORE CAPABILITIES & DOMAIN KNOWLEDGE:
        1. **Crop Health & Diagnostics**: Identify diseases, fungal infections (blast, blight, leaf spot), pests (stem borer, aphids, whitefly), and micronutrient deficiencies (Zinc, Iron, Boron).
        2. **Fertilizer & Soil Nutrition**: Balanced NPK management (Urea, DAP, SSP, MOP), organic manure (vermicompost, jeevamrutham, biofertilizers), and soil conditioning (lime for acidic soils, gypsum for saline/alkaline soils).
        3. **Climate & Water Management**: Advising on optimal spray windows, water-saving irrigation methods (drip, furrow), and unseasonal weather precautions.
        4. **Market & Mandi Advisory**: Selling decisions, quality drying, and moisture standards (e.g. 12-14% moisture) to fetch maximum MSP/modal prices.
        5. **Government Schemes & Subsidies**: Knowledge of PM-KISAN, Rythu Bharosa, crop insurance (PMFBY), and solar pump schemes.

        CRITICAL COMMUNICATION GUIDELINES:
        - Respond warmly and respectfully in **{language_name}**.
        - When speaking in Telugu, use natural, farmer-friendly terms (e.g., నమస్కారం రైతు సోదరులారా, ఎరువులు, చీడపీడలు, కషాయాలు, పిచికారీ).
        - Structure your response cleanly using bullet points or numbered steps so it is effortless to read on a mobile screen.
        - For high-risk disease or chemical inquiries, provide safe organic remedies alongside chemical controls, and remind the farmer to wear protective gear and consult their local Agriculture Extension Officer (AEO) or Rythu Bharosa Kendra (RBK).
        """


        if context:
            system_prompt += f"\n\n--- AVAILABLE FARM CONTEXT ---\n{context}\n------------------------------\n"

        full_prompt = f"{system_prompt}\n\nFarmer says: {message}"

        try:
            response = self.model.generate_content(full_prompt)
            return response.text.strip()
        except Exception as e:
            print(f"AI Service Error: {e}")
            raise Exception("Failed to generate response from AI Service")

    async def analyze_crop_image(self, image_data: bytes, language_code: str, crop_name: str = None, description: str = None) -> str:
        if not self.model or self.api_key == "your_gemini_api_key_here":
            raise ValueError("GEMINI_API_KEY environment variable is not set")
            
        language_name = self._get_language_name(language_code)
        
        import PIL.Image
        import io
        import json
        
        try:
            image = PIL.Image.open(io.BytesIO(image_data))
        except Exception as e:
            raise ValueError("Invalid image data")

        system_prompt = f"""
        You are RythuMitra AI, a professional agricultural AI agronomist and crop plant pathologist. 
        You are analyzing an image of a crop, plant, leaf, fruit, or stem to identify potential diseases, nutritional deficiencies, or pest infestations.
        
        IMPORTANT RULES:
        1. You MUST respond in {language_name}.
        2. You MUST return your response as a valid JSON object matching the exact schema provided.
        3. Maintain scientific honesty. Use phrases like "Possible issue", "May be consistent with", "Based on visible symptoms".
        4. Provide both Organic/Biological and Chemical treatments if a disease/pest is suspected.
        5. Include preventive cultural measures (spacing, water drainage, sanitation).
        """

        user_prompt = "Please analyze this crop image."
        if crop_name:
            user_prompt += f"\nCrop identified as: {crop_name}"
        if description:
            user_prompt += f"\nFarmer's description: {description}"
            
        user_prompt += """
        
        Respond ONLY with a valid JSON object with no markdown fences, matching this schema:
        {
          "cropName": "The detected crop (e.g. Rice, Tomato, Cotton, Chilli). If uncertain, provide your best inference.",
          "severityLevel": "Low / Moderate / High / Severe",
          "confidenceScore": "85%",
          "summary": "Short 2-line farmer-friendly diagnosis and condition summary.",
          "possibleIssues": [
            "Primary Disease / Pest Name",
            "Alternative possibility"
          ],
          "visibleSymptoms": [
            "Specific lesion, discoloration, spotting, or leaf curling observed"
          ],
          "treatmentOptions": {
            "organicTreatment": [
              "Bio-fungicide, Neem spray, or natural remedy"
            ],
            "chemicalTreatment": [
              "Standard recommended chemical spray with precautions"
            ],
            "preventiveMeasures": [
              "Spacing, water management, field hygiene"
            ]
          },
          "recommendedNextSteps": [
            "Action 1 to perform immediately",
            "Action 2 to monitor within 3-5 days"
          ],
          "whenToSeekExpertHelp": "Clear threshold when the farmer must contact local Agriculture Officer or KVK."
        }
        """

        try:
            response = self.model.generate_content([system_prompt, user_prompt, image])

            text_response = response.text.strip()
            
            # Clean up markdown code blocks if the model wrapped the JSON
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            if text_response.endswith("```"):
                text_response = text_response[:-3]
                
            return text_response.strip()
        except Exception as e:
            print(f"Vision Service Error: {e}")
            raise Exception("Failed to analyze image with AI Service")

    async def calculate_fertilizer(self, crop: str, area: float, unit: str) -> str:
        if not self.model:
            raise ValueError("GEMINI_API_KEY environment variable is not set")
            
        system_prompt = """
        You are an expert agronomist. 
        Given a crop type, area, and area unit, calculate the exact recommended amounts of MOP (Potash), TSP (Phosphate), and Urea (Nitrogen).
        Return ONLY a raw JSON object with no markdown wrappers or additional text, in this exact format:
        {
          "mop": "X kg / Y bags",
          "tsp": "X kg / Y bags",
          "urea": "X kg / Y bags"
        }
        (Assume 1 bag = 50kg). Be realistic based on general agricultural standards.
        """
        
        user_prompt = f"Crop: {crop}, Area: {area} {unit}"
        
        try:
            response = self.model.generate_content([system_prompt, user_prompt])
            text_response = response.text.strip()
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            if text_response.endswith("```"):
                text_response = text_response[:-3]
            return text_response.strip()
        except Exception as e:
            print(f"Fertilizer Calc Error: {e}")
            raise Exception("Failed to calculate fertilizer with AI Service")

    async def analyze_soil_data(self, soil_data: dict, language_code: str = "en") -> str:
        if not self.model or self.api_key == "your_gemini_api_key_here":
            raise ValueError("GEMINI_API_KEY environment variable is not set")

        language_name = self._get_language_name(language_code)

        system_prompt = f"""
        You are RythuMitra AI, an expert agricultural soil scientist and agronomist.
        Analyze the provided soil test values and provide actionable, farmer-friendly guidance.

        RULES:
        1. Respond in {language_name}.
        2. Keep advice practical, safe, and culturally relevant for Indian farmers.
        3. Recommend soil conditioners (Gypsum for alkaline/saline soils, Lime for acidic soils, organic manures/vermicompost for low organic carbon).
        4. Give specific fertilizer dosage guidance (NPK) according to the target crop.
        5. Return ONLY a valid JSON object matching the exact schema below, with no markdown code fences:
        {{
          "overallHealth": "Good / Moderate / Needs Conditioning / Deficient",
          "summary": "Short 2-3 sentence farmer-friendly summary of the soil condition in {language_name}",
          "phAnalysis": "Explanation of the pH level (Acidic / Neutral / Alkaline) and its impact",
          "nutrientAssessments": {{
            "nitrogen": "Low / Optimal / High - explanation",
            "phosphorus": "Low / Optimal / High - explanation",
            "potassium": "Low / Optimal / High - explanation",
            "organicCarbon": "Low / Optimal / High - explanation"
          }},
          "conditioningRecommendations": [
            "Actionable soil conditioning tip 1",
            "Actionable soil conditioning tip 2"
          ],
          "fertilizerPlan": [
            "Fertilizer dose & schedule recommendation 1",
            "Fertilizer dose & schedule recommendation 2"
          ],
          "suitableCrops": [
            "Crop 1", "Crop 2", "Crop 3"
          ],
          "warningNotes": "Important precautionary note or seasonal advice"
        }}
        """

        user_prompt = f"Soil Test Input Data:\n{soil_data}"

        try:
            response = self.model.generate_content([system_prompt, user_prompt])
            text_response = response.text.strip()
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            if text_response.endswith("```"):
                text_response = text_response[:-3]
            return text_response.strip()
        except Exception as e:
            print(f"Soil Analysis Error: {e}")
            raise Exception("Failed to analyze soil data with AI Service")

    async def analyze_soil_card_image(self, image_data: bytes, crop: str = None, language_code: str = "en") -> str:
        if not self.model or self.api_key == "your_gemini_api_key_here":
            raise ValueError("GEMINI_API_KEY environment variable is not set")

        language_name = self._get_language_name(language_code)

        import PIL.Image
        import io

        try:
            image = PIL.Image.open(io.BytesIO(image_data))
        except Exception as e:
            raise ValueError("Invalid image data")

        system_prompt = f"""
        You are RythuMitra AI. You are examining a Soil Health Card or Soil Lab Test Report photograph.
        Extract the visible soil test parameters (pH, EC, Nitrogen, Phosphorus, Potassium, Organic Carbon, Micronutrients) and provide an in-depth agronomic analysis.

        RULES:
        1. Respond in {language_name}.
        2. If values are unclear or partially obscured, state best estimates or note unreadable sections.
        3. Return ONLY a valid JSON object matching the exact schema below, with no markdown code fences:
        {{
          "overallHealth": "Good / Moderate / Needs Conditioning / Deficient",
          "summary": "Short farmer-friendly summary of the extracted soil test findings in {language_name}",
          "phAnalysis": "Explanation of detected pH level and recommendations",
          "nutrientAssessments": {{
            "nitrogen": "Status & value from report",
            "phosphorus": "Status & value from report",
            "potassium": "Status & value from report",
            "organicCarbon": "Status & value from report"
          }},
          "conditioningRecommendations": [
            "Recommendation 1",
            "Recommendation 2"
          ],
          "fertilizerPlan": [
            "Fertilizer dose recommendation 1",
            "Fertilizer dose recommendation 2"
          ],
          "suitableCrops": [
            "Crop 1", "Crop 2", "Crop 3"
          ],
          "warningNotes": "Important precaution or reminder"
        }}
        """

        user_prompt = "Please analyze this Soil Health Card report."
        if crop:
            user_prompt += f" Target Crop to cultivate: {crop}"

        try:
            response = self.model.generate_content([system_prompt, user_prompt, image])
            text_response = response.text.strip()
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            return text_response.strip()
        except Exception as e:
            print(f"Soil Card Vision Error: {e}")
            raise Exception("Failed to analyze soil card image with AI Service")

    async def generate_climate_advisory(self, weather_data: dict, crop: str = None, language_code: str = "en") -> str:
        if not self.model or self.api_key == "your_gemini_api_key_here":
            raise ValueError("GEMINI_API_KEY environment variable is not set")

        language_name = self._get_language_name(language_code)

        system_prompt = f"""
        You are RythuMitra AI, an agrometeorological specialist for Indian farmers.
        Given current weather observations and multi-day forecasts for a location, provide practical, protective agricultural climate advice.

        RULES:
        1. Respond in {language_name}.
        2. Evaluate spraying window: Safe when wind speed is under 15 km/h, rain probability is low (<2mm precipitation in next 24h), and temperature is not extreme (>35°C causes rapid evaporation).
        3. Evaluate irrigation need: Check upcoming rain. If significant rain (>10mm) is forecasted within 48h, advise holding off irrigation.
        4. Detect pest/disease risks: High humidity (>80%) + warm temperatures often trigger fungal blast, downy mildew, or sucking pests.
        5. Return ONLY a valid JSON object matching the exact schema below, with no markdown code fences:
        {{
          "summary": "Short 2-line farmer-friendly summary of current climate and advisory in {language_name}",
          "sprayingWindow": {{
            "isFavorable": true / false,
            "statusText": "Favorable Window / Unfavorable - Rain Risk / High Winds",
            "reason": "Clear explanation in {language_name}"
          }},
          "irrigationAdvice": {{
            "shouldIrrigate": true / false,
            "adviceText": "Watering advice tailored to soil and weather in {language_name}",
            "expectedRainAlert": "e.g. 15mm rain expected on Friday or null"
          }},
          "harvestingAdvice": "Guidance on harvesting, drying, or grain storage safety in {language_name}",
          "pestDiseaseRisk": "Pest & fungal alert based on humidity and temperatures in {language_name}",
          "severeAlerts": [
            {{
              "severity": "Warning / Severe / Moderate",
              "title": "Alert title",
              "description": "Protection measure for standing crops"
            }}
          ]
        }}
        """

        user_prompt = f"Weather Data: {weather_data}\nTarget Crop: {crop or 'General Agricultural Crops'}"

        try:
            response = self.model.generate_content([system_prompt, user_prompt])
            text_response = response.text.strip()
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            if text_response.endswith("```"):
                text_response = text_response[:-3]
            return text_response.strip()
        except Exception as e:
            print(f"Climate Advisory Error: {e}")
            raise Exception("Failed to generate climate advisory with AI Service")

    async def analyze_market_insights(self, crop: str, prices: list, language_code: str = "en") -> str:
        if not self.model or self.api_key == "your_gemini_api_key_here":
            raise ValueError("GEMINI_API_KEY environment variable is not set")

        language_name = self._get_language_name(language_code)

        system_prompt = f"""
        You are RythuMitra AI, a trusted agricultural market advisor for Indian farmers.
        Given mandi market price records for a crop, generate an actionable price trend insight.

        RULES:
        1. Respond in {language_name}.
        2. Identify the highest paying mandi and average modal price.
        3. Advise on selling decisions (e.g., whether to hold produce, dry properly to meet FAQ standards, or transport to nearby high-paying APMC mandis).
        4. Return ONLY a valid JSON object matching the exact schema below, with no markdown code fences:
        {{
          "headline": "Short 1-line market trend headline in {language_name}",
          "bestMarket": "Name of the highest paying market and district",
          "priceTrend": "Steady / Bullish / Bearish / Highly Volatile",
          "advisory": "Practical advice for the farmer on selling or holding this produce in {language_name}",
          "storageTip": "Crop-specific post-harvest storage and moisture tip to avoid market deductions in {language_name}"
        }}
        """

        user_prompt = f"Crop: {crop}\nMandi Price Records: {prices}"

        try:
            response = self.model.generate_content([system_prompt, user_prompt])
            text_response = response.text.strip()
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            if text_response.endswith("```"):
                text_response = text_response[:-3]
            return text_response.strip()
        except Exception as e:
            print(f"Market Insight Error: {e}")
            raise Exception("Failed to generate market insights with AI Service")

# Create a singleton instance
ai_service = AIService()

