import json
import requests


def filter_input(text: str) -> bool:
    text_lower = text.lower()
    return not any(word in text_lower for word in ["kill", "weapon", "drugs", "hack"])


def get_core_prompt(config):
    return f"""
Jesteś chatbotem pizzerii.

Twoim zadaniem jest rozpoznanie intencji użytkownika i odpowiednie zareagowanie.

Intencje użytkownika:
1. Powitanie:
   - "Cześć", "Hej", "Dzień dobry"
   - Odpowiadasz krótkim powitaniem

2. MENU:
   - "Menu", "Co sprzedajecie", "Jak jest wasza oferta"
   - Podajesz menu z cenami w formie: Pozycja: cena + PLN

3. Lokalizacje restauracji
   - "Gdzie macie lokale"
   - Podajesz listę maiast

Fallback, brak intencji lub niejasna wiadomość:
jeśli użytkownik niejasno sformułuje wiadomość lub nie pasuje do żadnej intencji wtedy:
  poproś o doprecyzowanie i ponownie przedstaw dostępne możliwości:  podawanie godzin otwarcia, prezentowanie menu z cenami, informowanie o lokalizacji restauracji

DANE RESTAURACJI:
Godziny otwarcia:
{config['schedule']}

Menu:
{config['menu']}

Lokalizacje:
{config['locations']}

Zasady:
- Odpowiadaj krótko
- Nie zadawaj wielu pytań naraz
"""

config = None
with open("config.json", "r") as f:
    config = json.load(f)
core_prompt = get_core_prompt(config)


def send_prompt(user_text):
    if not filter_input(user_text):
        print("ChatBot: Nie mogę odpowiedzieć na tę wiadomość.")
        return

    response = requests.post(
        "http://localhost:11434/api/chat",
        json={
            "model": "llama3",
            "messages": [
                {"role": "system", "content": core_prompt},
                {"role": "user", "content": user_text}
            ],
            "stream": False
        }
    )

    return response.json()["message"]["content"]


if __name__ == "__main__":
    print("Start")
    while True:
        prompt = input("Ty: ")
        response = send_prompt(prompt)
        print("ChatBot:", response)
