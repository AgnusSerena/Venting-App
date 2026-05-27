from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import pipeline
import random

# ---------------- APP ---------------- #

app = Flask(__name__)
CORS(app)

# ---------------- EMOTION MODEL ---------------- #

emotion_model = pipeline(
    "text-classification",
    model="j-hartmann/emotion-english-distilroberta-base",
    top_k=None,
    device=-1
)

# ---------------- NORMALIZE ---------------- #

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

# ---------------- ANALYZE EMOTION ---------------- #

def analyze_emotion(text):

    results = emotion_model(text)[0]

    best = max(results, key=lambda x: x['score'])

    emotion = normalize(best['label'])

    confidence = best['score']

    return emotion, confidence

# ---------------- GENERATE HUMAN RESPONSE ---------------- #

def generate_response(user_text, emotion):

    text = user_text.lower()

    # ---------------- SAD ---------------- #

    if emotion == "sad":

        if "depress" in text:

            return (
                "I'm really sorry you're feeling this way. "
                "It sounds like things have been emotionally exhausting lately. "
                "You don’t have to carry everything alone."
            )

        elif "lonely" in text:

            return (
                "Feeling lonely can hurt a lot sometimes. "
                "I’m here with you, and you deserve someone who truly listens."
            )

        elif "heavy" in text:

            return (
                "That emotional heaviness can become really overwhelming after a while. "
                "Try not to be too hard on yourself right now."
            )

        elif "cry" in text:

            return (
                "It’s okay to cry sometimes. "
                "You’ve probably been holding in a lot more than people realize."
            )

        elif "tired" in text:

            return (
                "You sound emotionally drained. "
                "Maybe you've been trying to stay strong for too long."
            )

        else:

            responses = [

                "That sounds really difficult. I'm here to listen to you.",

                "I know things may feel overwhelming right now, but your feelings matter.",

                "You deserve support and kindness too, especially during hard moments.",

                "You don’t always have to pretend to be okay."
            ]

            return random.choice(responses)

    # ---------------- FEAR / ANXIETY ---------------- #

    elif emotion == "fear":

        if "can't breathe" in text or "panic" in text:

            return (
                "I’m here with you. "
                "Try taking one slow breath at a time. "
                "You’re safe right now."
            )

        elif "anxious" in text:

            return (
                "Anxiety can make everything feel overwhelming. "
                "You don’t need to solve everything all at once."
            )

        else:

            responses = [

                "That sounds overwhelming, but you’re not alone in this.",

                "Take things one step at a time. You’re doing better than you think.",

                "I’m here with you through this."
            ]

            return random.choice(responses)

    # ---------------- ANGER ---------------- #

    elif emotion == "angry":

        responses = [

            "That sounds really frustrating. I can understand why you'd feel upset.",

            "It’s okay to feel angry sometimes. Your feelings are valid.",

            "You’ve probably been holding a lot inside for a while."
        ]

        return random.choice(responses)

    # ---------------- HAPPY ---------------- #

    elif emotion == "happy":

        responses = [

            "That honestly made me smile too 😊",

            "I’m really glad something good happened for you today.",

            "You deserve moments like this."
        ]

        return random.choice(responses)

    # ---------------- NEUTRAL ---------------- #

    else:

        responses = [

            "I’m listening. Tell me more about that.",

            "How has your day been emotionally?",

            "I’m here with you.",

            "What’s been on your mind lately?"
        ]

        return random.choice(responses)

# ---------------- CHAT API ---------------- #

@app.route("/chat", methods=["POST"])
def chat():

    data = request.get_json()

    user_text = data.get("message", "")

    if not user_text:

        return jsonify({
            "reply": "Please say something."
        })

    # ---------------- EMOTION + CONFIDENCE ---------------- #

    emotion, confidence = analyze_emotion(user_text)

    print(f"Emotion: {emotion}")
    print(f"Confidence: {confidence}")

    # ---------------- CONFIDENCE CHECK ---------------- #

    if confidence > 0.90:

        reply = generate_response(user_text, emotion)

    else:

        reply = (
            "I'm here with you. "
            "Tell me more about what's on your mind."
        )

    return jsonify({
        "reply": reply
    })

# ---------------- HOME ---------------- #

@app.route("/")
def home():

    return "Emotion AI Backend Running"



if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000
    )