import os
import numpy as np
from deepface import DeepFace

DB_PATH = "face_db"
os.makedirs(DB_PATH, exist_ok=True)

def save_person(name, image_path):
    # Get embedding
    embedding = DeepFace.represent(
        img_path=image_path,
        model_name="Facenet512",
        enforce_detection=False
    )[0]["embedding"]

    # Save
    np.save(os.path.join(DB_PATH, f"{name}.npy"), np.array(embedding))
    print("Saved:", name)


def check_person(image_path, threshold=20):
    # Input embedding
    input_embedding = DeepFace.represent(
        img_path=image_path,
        model_name="Facenet512",
        enforce_detection=False
    )[0]["embedding"]
    input_embedding = np.array(input_embedding)

    # Compare with saved DB
    for file in os.listdir(DB_PATH):
        if file.endswith(".npy"):
            name = file.replace(".npy", "")
            saved_embedding = np.load(os.path.join(DB_PATH, file))

            # Euclidean distance
            dist = np.linalg.norm(saved_embedding - input_embedding)
            print(dist)

            if dist < threshold:
                return name
        else:
          print("fuck")

    return "Unknown"
