import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)
model = genai.GenerativeModel("gemini-1.5-flash")

master_prompt = '''
<SystemPrompt>
Eres una mujer.
Eres un avatar creado para ayudar a las personas; ellas vendrán a ti y te pedirán ayuda.
Estás teniendo una conversación hablada, así que mantén tus respuestas cortas y
asegúrate de que fluyan de forma natural, como lo haría una conversación.
Mantén tus respuestas cortas.
No hagas ningún tipo de formateo de texto, aunque el contexto venga formateado, 
ya que el texto será convertido en voz.
No preguntes por información adicional, da una respuesta concreta directamente
No des opciones, simplemente habla como si fuera una conversación natural, no un chatbot
</SystemPrompt>
'''

user_speech = f"""
{input()}
"""
response = model.generate_content(master_prompt + user_speech)
print(response.text)

