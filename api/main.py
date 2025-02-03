from fastapi import FastAPI, Query
from pymongo import MongoClient
import os

app = FastAPI()

MONGO_URI = os.getenv("MONGO_URI")
if not MONGO_URI:
    raise ValueError("MONGO_URI is not set! Add it in Vercel environment variables.")

client = MongoClient(MONGO_URI)
db = client["GymFlow"]
col = db["Exercises"]
col2 = db["Food"]

@app.get("/")
def greet():
    return {"message": "Hello bro, it's working!"}

@app.get("/calculate_bmi")
def calculate_bmi(weight: float, height: float, age: int, gender: str):
    bmi = weight / (height ** 2)

    if gender.lower() == 'male':
        body_fat = (1.20 * bmi) + (0.23 * age) - 16.2
    elif gender.lower() == 'female':
        body_fat = (1.20 * bmi) + (0.23 * age) - 5.4
    else:
        return {"error": "Invalid gender, please enter 'male' or 'female'"}
    result = {
        "bmi": round(bmi, 2),
        "body_fat_percentage": round(body_fat, 2)
    }
    return result

@app.get("/find_exercise")
def find_exercise(name: str):
    query = {"Name": name}
    results = col.find(query, {"_id": 0})
    
    return list(results)

@app.get("/get_cards")
def get_cards():
    result = col.find({}, {"_id": 0, "Title": 1, "Muscle": 1})  
    return list(result)

@app.get("/get_FoodCards")
def get_cards():
    result = col2.find({}, {"_id": 0, "name": 1, "calories": 1})  
    return list(result)
