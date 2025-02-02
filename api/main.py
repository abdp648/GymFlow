from fastapi import FastAPI
from typing import Optional

app = FastAPI()

@app.get()
async def greet():
    return "hello bro , vercel is the best one in my life"
