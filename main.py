from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import pipeline
from google import genai

app = Flask(__name__)
CORS(app)

client = genai.Client(
    api_key="YOUR_GEMINI_API_KEY"
)

emotion_model = pipeline(
    "text-classification",
    model="j-hartmann/emotion-english-distilroberta-base",
    top_k=None,
    device=-1
)

conversation_history = []

MAX_MEMORY = 8

def normalize(label):

    mapping = {

        "sadness": "sad",
        "joy": "happy",
        "anger": "angry",
        "fear": "fear",
        "surprise": "surprise",
        "disgust": "disgust",
        "neutral": "neutral"
    }

    return mapping.get(label, label)

def analyze_emotion(text):

    results = emotion_model(text)[0]

    best = max(
        results,
        key=lambda x: x['score']
    )

    emotion = normalize(
        best['label']
    )

    confidence = best['score']

    return emotion, confidence

def build_memory_context():

    memory = ""

    recent_messages = conversation_history[-MAX_MEMORY:]

    for msg in recent_messages:

        role = msg["role"]

        text = msg["text"]

        memory += f"{role}: {text}\n"

    return memory

def generate_ai_response(
    user_text,
    emotion
):

    memory_context = build_memory_context()

    prompt = f"""
You are a compassionate emotional wellness companion.

Conversation History:
{memory_context}

Current User Emotion:
{emotion}

Current User Message:
{user_text}

Rules:
- sound like a caring human
- emotionally supportive
- natural conversation
- conversational tone
- short meaningful replies
- continue previous conversation naturally
- never mention AI
- never sound robotic
"""

    try:

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt
        )

        return response.text

    except Exception as e:

        print("Gemini Error:", e)

        fallback = {

            "sad":
                "I'm really sorry you're feeling this way. I'm here with you.",

            "happy":
                "That honestly sounds really nice 😊",

            "angry":
                "That sounds frustrating. Take a slow breath for a moment.",

            "fear":
                "You're safe right now. Try taking things one step at a time.",

            "neutral":
                "I'm listening. Tell me more about what's on your mind."
        }

        return fallback.get(
            emotion,
            "I'm here with you."
        )

@app.route("/chat", methods=["POST"])
def chat():

    data = request.get_json()

    user_text = data.get(
        "message",
        ""
    )

    if not user_text:

        return jsonify({

            "reply":
                "Please say something."

        })

    emotion, confidence = analyze_emotion(
        user_text
    )

    print(f"Emotion: {emotion}")
    print(f"Confidence: {confidence}")

    conversation_history.append({

        "role": "User",
        "text": user_text

    })

    if confidence > 0.90:

        reply = generate_ai_response(
            user_text,
            emotion
        )

    else:

        reply = (
            "I'm here with you. "
            "Tell me more about what you're feeling."
        )

    conversation_history.append({

        "role": "Assistant",
        "text": reply

    })

    if len(conversation_history) > 20:

        conversation_history.pop(0)

    return jsonify({

        "reply": reply,

        "emotion": emotion,

        "confidence": confidence
    })

@app.route("/")
def home():

    return "Emotion AI Backend Running"

if __name__ == "__main__":

    app.run(

        host="0.0.0.0",

        port=5000
    )