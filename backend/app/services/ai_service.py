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
        You are RythuMitra AI, a helpful and professional farming companion designed for farmers.
        
        IMPORTANT RULES:
        1. Communicate clearly and simply.
        2. You MUST respond in {language_name}.
        3. Ask follow-up questions when important information is missing.
        4. Avoid pretending to know uncertain information.
        5. Avoid overconfident agricultural advice.
        6. Encourage expert assistance for high-risk or uncertain situations.
        7. DO NOT falsely claim that you have analyzed a crop image, live weather data, current market prices, or farm information that was not explicitly provided in the user's prompt.
        8. The provided context is static saved profile data, not live sensor data. Do not treat it as current observation.
        9. If the user mentions a crop issue and multiple crops are in the context, do NOT guess which crop they mean. ALWAYS ask them which crop they are referring to before giving advice.
        10. If a 'focusedCrop' is provided in the context, it means the user is currently looking at or asking specifically about that crop. Assume they are talking about this crop unless they explicitly change the subject.
        11. If 'healthHistoryContext' is provided, it contains past AI scans and farmer follow-up updates. Use this strictly as background context. DO NOT claim that a past 'possible issue' is a confirmed diagnosis. Use phrasing like "Based on the previous scan and your follow-up information..."
        12. If market prices are provided in the context, use them to answer the user's questions. DO NOT guarantee future prices, profit, market movement, or guaranteed buyer price. Use phrasing like "Based on available reported market data..." or "Prices can change."
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
        You are RythuMitra AI, a professional agricultural AI assistant. You are analyzing an image of a crop or leaf to help a farmer identify potential issues.
        
        IMPORTANT RULES:
        1. You MUST respond in {language_name}.
        2. You MUST return your response as a valid JSON object matching the exact schema provided.
        3. DO NOT claim absolute certainty. Use phrases like "Possible issue", "May be consistent with", "Based on visible symptoms".
        4. If the image is unclear or not a plant, clearly state that in the summary.
        5. DO NOT recommend specific chemical dosages. Recommend checking with an expert.
        """

        user_prompt = "Please analyze this crop image."
        if crop_name:
            user_prompt += f"\nCrop identified as: {crop_name}"
        if description:
            user_prompt += f"\nFarmer's description: {description}"
            
        user_prompt += """
        
        Respond ONLY with a JSON object in this exact format, with no markdown formatting around it:
        {
          "summary": "A short farmer-friendly summary of the observation.",
          "possibleIssues": ["Issue 1", "Issue 2"],
          "visibleSymptoms": ["Symptom 1", "Symptom 2"],
          "recommendedNextSteps": ["Step 1", "Step 2"],
          "whenToSeekExpertHelp": "Advice on when to consult an expert."
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

# Create a singleton instance
ai_service = AIService()
