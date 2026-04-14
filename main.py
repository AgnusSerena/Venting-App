from transformers import pipeline
import os

# ------------------ MODELS ------------------

text_model = pipeline(
    "text-classification",
    model="j-hartmann/emotion-english-distilroberta-base"
)

audio_model = pipeline(
    "audio-classification",
    model="superb/wav2vec2-base-superb-er"
)

# ------------------ HELPERS ------------------

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

def get_top(result):
    return max(result, key=lambda x: x['score'])

# ------------------ COMBINE ------------------

def combine(text_em, audio_em):
    t_label = normalize(text_em['label'])
    a_label = normalize(audio_em['label'])

    t_score = text_em['score']
    a_score = audio_em['score']

    if t_label == a_label:
        return {"final": t_label, "reason": "both agree"}

    if a_score > t_score:
        return {"final": a_label, "reason": "voice higher confidence"}

    return {"final": t_label, "reason": "text higher confidence"}

# ------------------ MAIN ------------------

text = input("Enter text: ")

audio_path = "sample.wav"

# TEXT ALWAYS AVAILABLE
text_result = get_top(text_model(text))

# CHECK IF AUDIO EXISTS
if os.path.exists(audio_path):
    audio_result = get_top(audio_model(audio_path))
    final = combine(text_result, audio_result)

    print("\nMode: TEXT + AUDIO")
    print("Text Emotion:", text_result)
    print("Audio Emotion:", audio_result)

else:
    final = {
        "final": normalize(text_result['label']),
        "reason": "text only"
    }

    print("\nMode: TEXT ONLY")
    print("Text Emotion:", text_result)

print("Final Decision:", final)