
# Imports the Google Cloud client library


from google.cloud import speech
import sys


def run_quickstart() -> speech.RecognizeResponse:
    # Instantiates a client
    client = speech.SpeechClient()

    # The name of the audio file to transcribe
    gcs_uri = "gs://cloud-samples-data/speech/brooklyn_bridge.raw"

    with open(sys.argv[1], "rb") as f:
        audio_content = f.read()

    audio = speech.RecognitionAudio(content=audio_content)

    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        # sample_rate_hertz=8000,
        language_code="es-US",
        audio_channel_count=2,
        enable_separate_recognition_per_channel=False, #it bills per channel     
    )

    # Detects speech in the audio file
    response = client.recognize(config=config, audio=audio)
    print(response, file=sys.stderr)
    for result in response.results:
        print(result.alternatives[0].transcript)

if __name__ == "__main__":
    run_quickstart()