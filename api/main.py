from fastapi import FastAPI, Query
from pymongo import MongoClient
import os
from typing import Union
from hashlib import sha256

app = FastAPI()

MONGO_URI = os.getenv("MONGO_URI")
if not MONGO_URI:
    raise ValueError("MONGO_URI is not set! Add it in Vercel environment variables.")

client = MongoClient(MONGO_URI)
db = client["GymFlow"]
col = db["Exercises"]
col2 = db["Food"]
col3 = db["Accounts"]

@app.get("/")
def greet():
    return {"message": "Hello bro, it's working!"}

#here is bmi bro

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

#here is excersizes

@app.get("/find_exercise")
def find_exercise(name: str):
    query = {"Name": name}
    results = col.find(query, {"_id": 0})
    
    return list(results)

@app.get("/get_cards")
def get_cards():
    result = col.find({}, {"_id": 0, "Title": 1, "Muscle": 1})  
    
    return list(result)

#abdo, here is the food

@app.get("/get_FoodCards")
def get_FoodCards():
    result = col2.find({}, {"_id": 0, "name": 1, "calories": 1})  
    
    return list(result)

@app.get("/find_food")
def find_Food(name: str):
    query = {"name": name}
    results = col2.find(query, {"_id": 0})
    
    return list(results)

# accounts is here, abdo 

@app.get("/add_acc")
def add_acc(user: str, password: Union[str, int]):
    hashed_password = sha256(str(password).encode()).hexdigest()
    query = {"User": user, "Pass": hashed_password}
    col3.insert_one(query)
    
    return "Signed Up successfully"

@app.get("/login")
def login(user: str, password: Union[str, int]):
    user_data = col3.find_one({"User": user})  

    if user_data:
        stored_hashed_password = user_data["Pass"]
        entered_hashed_password = sha256(str(password).encode()).hexdigest()
        if entered_hashed_password == stored_hashed_password:
            return "Login successful"
        else:
            return "Invalid password"
    else:
        return "User not found"