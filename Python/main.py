import json
import requests
from prompt import build_system_prompt


def filter_input(text: str) -> bool:
    text_lower = text.lower()
    return not any(word in text_lower for word in ["kill", "weapon", "drugs", "hack"])

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llama3"

# wczytanie configu
with open("config.json", "r") as f:
    config = json.load(f)

SYSTEM_PROMPT = build_system_prompt(config)

def ask_llm(user_input):
    payload = {
        "model": MODEL,
        "prompt": SYSTEM_PROMPT + "\nUżytkownik: " + user_input + "\nAsystent:",
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)
    return response.json()["response"]


def chat():
    print("Czatbot uruchomiony. (exit aby zakończyć)")

    while True:
        user_input = input("Ty: ")

        if user_input.lower() == "exit":
            break

        # filtr
        if not filter_input(user_input):
            print("Bot: Nie mogę odpowiedzieć na tę wiadomość.")
            continue

        response = ask_llm(user_input)
        print("Bot:", response)


if __name__ == "__main__":
    chat()
