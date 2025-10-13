from flask import Flask, request, jsonify
import random

app = Flask(__name__)

@app.route('/generate_quiz', methods=['POST'])
def generate_quiz():
    try:
        data = request.get_json()
        topic = data.get('topic', 'General')

        # Sample question bank (replace this with dynamic logic if using OpenAI or DB)
        question_bank = {
            "C Programming": [
                {
                    "question": "What is the size of int in C?",
                    "options": ["2 bytes", "4 bytes", "8 bytes", "Depends on compiler"],
                    "answer": "Depends on compiler"
                },
                {
                    "question": "Which of the following is a valid C variable name?",
                    "options": ["int", "_value", "2name", "float"],
                    "answer": "_value"
                },
            ],
            "COA": [
                {
                    "question": "What does ALU stand for?",
                    "options": ["Arithmetic Logic Unit", "Array Logic Unit", "Application Logic Unit", "None"],
                    "answer": "Arithmetic Logic Unit"
                },
                {
                    "question": "What is cache memory used for?",
                    "options": ["Long-term storage", "Speeding up access", "Storing graphics", "None"],
                    "answer": "Speeding up access"
                },
            ],
            "DSGT": [
                {
                    "question": "What is the primary goal of a data structure?",
                    "options": ["To store data", "To organize and access data efficiently", "To compile code", "To debug programs"],
                    "answer": "To organize and access data efficiently"
                },
                {
                    "question": "Which of these is a linear data structure?",
                    "options": ["Tree", "Graph", "Stack", "Hash Table"],
                    "answer": "Stack"
                },
            ]
        }

        # Get questions for topic or fallback
        questions = question_bank.get(topic, [])
        if not questions:
            return jsonify({"quiz": []}), 200

        # Shuffle & limit
        random.shuffle(questions)
        return jsonify({"quiz": questions[:5]}), 200

    except Exception as e:
        print("Error in /generate_quiz:", e)
        return jsonify({"quiz": [], "error": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)