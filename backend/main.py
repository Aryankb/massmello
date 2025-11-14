from fastapi import FastAPI, UploadFile, File, Form
from pydantic import BaseModel
from whatsapp import call, send_whatsapp_message
from face import save_person, check_person
import uuid
import shutil
import os
app = FastAPI()

class AlertRequest(BaseModel):
    text: str
    mobile_number: str = "917000978867"

@app.post("/send_alert_to_family")
async def send_alert_to_family(alert: AlertRequest):
    send_whatsapp_message(text=alert.text, number=alert.mobile_number)
    call(phone_number=alert.mobile_number)
    return {"status": "success", "message": "Alert sent successfully"}


@app.post("/save_person")
async def save_person(
    name: str = Form(...),
    image: UploadFile = File(...)
):
    # Generate 6-digit UUID
    unique_id = str(uuid.uuid4().int)[:6]
    person_identifier = f"{name}_{unique_id}"
    
    # Create temp directory if not exists
    temp_dir = "temp_uploads"
    os.makedirs(temp_dir, exist_ok=True)
    
    # Save uploaded image temporarily
    temp_image_path = os.path.join(temp_dir, f"{person_identifier}.jpg")
    with open(temp_image_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
    
    # Save person to face database
    save_person(person_identifier, temp_image_path)
    
    # Optional: Clean up temp file after saving
    os.remove(temp_image_path)
    
    return {
        "status": "success",
        "message": "Person registered successfully",
        "person_id": person_identifier,
    }


@app.post("/check_person")
async def check_person_endpoint(
    image: UploadFile = File(...)
):
    # Create temp directory if not exists
    temp_dir = "temp_uploads"
    os.makedirs(temp_dir, exist_ok=True)
    
    # Save uploaded image temporarily
    temp_image_path = os.path.join(temp_dir, f"check_{uuid.uuid4().hex}.jpg")
    with open(temp_image_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
    
    # Check person in face database
    person_name = check_person(temp_image_path)
    
    # Clean up temp file after checking
    os.remove(temp_image_path)
    
    return {
        "status": "success",
        "person_name": person_name
    }



