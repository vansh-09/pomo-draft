from flask import Flask, request, jsonify
from google.genai import Client

app = Flask(__name__)
client = Client(api_key="AIzaSyAo-kTX8LV0aMJ9EV_hdSdBkQq9_6Hj_cs")

@app.route("/generate_quiz", methods=["POST"])
def generate_quiz():
    topic = request.json.get("topic")
    if not topic:
        return jsonify({"error": "Topic is required"}), 400

    prompt = f"Generate 5 multiple-choice questions about {topic}, each with 4 options and the correct answer."

    response = client.chat(messages=[{"role": "user", "content": prompt}])
    questions = parse_questions(response["choices"][0]["message"]["content"])

    return jsonify({"quiz": questions})

def parse_questions(content):
    # Implement parsing logic here
    return [{"question": "Sample question", "options": ["A", "B", "C", "D"], "answer": "A"}]

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)