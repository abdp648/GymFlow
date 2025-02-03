from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

MONGO_URI = os.getenv("MONGO_URI")
if not MONGO_URI:
    raise ValueError("MONGO_URI is not set! Add it in Vercel environment variables.")

client = AsyncIOMotorClient(MONGO_URI)
db = client["GymFlow"]
exercises_collection = db["Exercises"]
food_collection = db["Food"]

@app.get("/")
def greet():
    return {"message": "Hello bro, it's working!"}

@app.get("/calculate_bmi")
def calculate_bmi(weight: float, height: float, age: int, gender: str):
    if height <= 0 or weight <= 0 or age <= 0:
        raise HTTPException(status_code=400, detail="Invalid input values!")

    bmi = weight / (height ** 2)
    body_fat = None

    if gender.lower() == "male":
        body_fat = (1.20 * bmi) + (0.23 * age) - 16.2
    elif gender.lower() == "female":
        body_fat = (1.20 * bmi) + (0.23 * age) - 5.4
    else:
        raise HTTPException(status_code=400, detail="Invalid gender! Use 'male' or 'female'.")

    return {
        "bmi": round(bmi, 2),
        "body_fat_percentage": round(body_fat, 2),
        "category": (
            "Underweight" if bmi < 18.5 else
            "Normal weight" if 18.5 <= bmi < 24.9 else
            "Overweight" if 25 <= bmi < 29.9 else
            "Obese"
        )
    }

@app.get("/find_exercise")
async def find_exercise(name: str):
    results = await exercises_collection.find_one({"Name": name}, {"_id": 0})
    
    if not results:
        raise HTTPException(status_code=404, detail="Exercise not found")
    
    return results

@app.get("/get_cards")
async def get_cards(skip: int = 0, limit: int = 10):
    cursor = exercises_collection.find({}, {"_id": 0, "Title": 1, "Muscle": 1}).skip(skip).limit(limit)
    result = await cursor.to_list(length=limit)
    
    if not result:
        raise HTTPException(status_code=404, detail="No exercises found")
    
    return {"exercises": result}

@app.get("/get_foods")
async def get_foods():
    cursor = food_collection.find({}, {"_id": 0, "name": 1, "calories": 1})
    food_list = await cursor.to_list(length=100)

    if not food_list:
        raise HTTPException(status_code=404, detail="No food items found")

    return {"foods": food_list}

@app.get("/find_food")
async def find_food(name: str):
    food = await food_collection.find_one({"name": name}, {"_id": 0})

    if not food:
        raise HTTPException(status_code=404, detail="Food not found")

    return food
