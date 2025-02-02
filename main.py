from fastapi import FastAPI

app = FastAPI()

@app.get()
async def greet():
    return "hello bro , vercel is the best one in my life"