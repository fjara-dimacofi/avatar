import socket
import struct
from RealtimeSTT import AudioToTextRecorder

HOST = "127.0.0.1"  # Match Godot script
PORT = 5000

recorder = AudioToTextRecorder(use_microphone=False, spinner=False)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
    server_socket.bind((HOST, PORT))
    server_socket.listen()
    print("Waiting for connection...")

    while True:
        try:
            conn, addr = server_socket.accept()
            print(f"Connected by {addr}")
            while True:
                size_bytes = conn.recv(4)
                if not size_bytes:
                    print(f"{addr} disconnected")
                    break

                size = struct.unpack("I", bytes(size_bytes))[0]
                audio_chunk = conn.recv(size)

                print("size: ", size)
                if not audio_chunk:
                    print(f"{addr} disconnected")
                    break
                print("audio chunk: ", audio_chunk)

                recorder.feed_audio(audio_chunk)
            print("here")
            print("Transcription:", recorder.text())
        except KeyboardInterrupt:
            print("\nShutting down")
            break
