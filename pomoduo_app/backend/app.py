import requests

def generate_quiz(topic):
    url = "https://api-inference.huggingface.co/models/iarfmoose/t5-base-question-generator"
    headers = {"Authorization": f"Bearer YOUR_API_TOKEN"}

    # Prepare the input for the model
    context = f"Explain the concept of {topic}."
    answer = f"A concept in {topic}."
    inputs = f"<answer> {answer} <context> {context}"

    response = requests.post(url, headers=headers, json={"inputs": inputs})

    if response.status_code == 200:
        question = response.json()[0]['generated_text']
        return [{"question": question, "options": ["A", "B", "C", "D"], "correct_index": 0}]
    else:
        return [{"question": "Error generating question", "options": [], "correct_index": -1}]