import sys
from faster_whisper import WhisperModel

model_size = "large-v3"
audio_file = sys.argv[1]
model = WhisperModel(model_size, device="cpu", compute_type="int8")
segments, info = model.transcribe(audio_file, beam_size=5, hotwords="ripley jumbo preunic")
for segment in segments:
    print(segment.text)
