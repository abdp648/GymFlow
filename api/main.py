from fastapi import FastAPI, Query
from starlette.middleware.cors import CORSMiddleware
import pymongo

myclient = pymongo.MongoClient('mongodb+srv://abdoeisaebrahim2011:abdoeisa2011@cluster0.9yxwg.mongodb.net/')
db = myclient['GymFlow']
col = db['Exercises']

app = FastAPI()
@app.get("/")
def greet():
    return "Hello bro it's working"
@app.post("/calculate_bmi")
def calculate_bmi(weight: float, height: float, age: int, gender: str):
    bmi = weight / (height ** 2)

    if gender.lower() == 'male':
        body_fat = (1.20 * bmi) + (0.23 * age) - 16.2
    elif gender.lower() == 'female':
        body_fat = (1.20 * bmi) + (0.23 * age) - 5.4
    else:
        return {"error": "Invalid gender, please enter 'male' or 'female'"}
    
    return {
        "bmi": round(bmi, 2),
        "body_fat_percentage": round(body_fat, 2)
    }

@app.get("/find_Exercize")
def find_Exercize(name: str = Query(...)):
    query = {"Name" : name}
    results = col.find(query)
    result_list = [
        {"Title": doc.get("Title"), 
        "Name": doc.get("Name"), 
        "Muscle": doc.get("Muscle"),
        "Tool": doc.get("Tool"),
        "VideoId": doc.get("VideoId")} 
        for doc in results]
    
    return result_list

@app.get("/get_Cards")
def get_Cards():
    result = col.find({}, {"_id": 0, "Title": 1 , "Muscle": 1})  
    titles_and_muscles = [{"Title": doc["Title"], "Muscle": doc["Muscle"]} for doc in result]
    
    return titles_and_muscles
