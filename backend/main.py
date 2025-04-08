# 로컬로 서버 실행 명령어 (VISIBLE 폴더에서 실행)
# export PYTHONPATH=. ; uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
# FastAPI 실행 진입점
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
import openai
import base64
from backend.gpt_service import analyze_image_and_question

app = FastAPI()

class AnalyzeRequest(BaseModel):
    image_base64: str
    question: str

@app.post("/analyze")
async def analyze(req: AnalyzeRequest):
    try:
        result = await analyze_image_and_question(req.image_base64, req.question)
        return {"summary": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
