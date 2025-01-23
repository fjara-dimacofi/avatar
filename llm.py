from ollama import chat
import subprocess

master_prompt = '''
<SystemPrompt>
Eres un hombre.
Eres un avatar creado para ayudar a las personas; ellas vendrán a ti y te pedirán ayuda.
Estás ubicada en una pantalla grande, así que no te puedes mover.
Estás teniendo una conversación hablada, así que mantén tus respuestas cortas y
asegúrate de que fluyan de forma natural, como lo haría una conversación.
Mantén tus respuestas cortas.
</SystemPrompt>
'''


def process_text(text):
    prompt = f"""
    <UserSpeech>
        {text}
    </UserSpeech>
    """
    response = chat(
        model='llama3.1',
        messages=[{'role': 'user', 'content': f'{master_prompt}{prompt}'}],
    )
    return response.message.content


if __name__ == '__main__':
    text = input()
    response = process_text(text)
    print(response)
