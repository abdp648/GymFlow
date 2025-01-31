from typing import Optional

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/bmi")
def calculate_bmi(weight: float, height: float):
    """
    Calculate Body Mass Index (BMI)
    Weight in kilograms
    Height in meters
    """
    if height <= 0:
        return {"error": "Height must be greater than 0"}
    
    bmi = weight / (height ** 2)
    
    category = ""
    if bmi < 18.5:
        category = "Underweight"
    elif 18.5 <= bmi < 24.9:
        category = "Normal weight"
    elif 25 <= bmi < 29.9:
        category = "Overweight"
    else:
        category = "Obesity"
    
    return {"BMI": round(bmi, 2), "Category": category}
