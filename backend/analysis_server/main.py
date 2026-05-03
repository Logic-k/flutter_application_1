from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
import random
import time

"""
MemoryLink 분석 백엔드 (FastAPI)
[agency-backend-architect]: 사용자가 안심하고 사용할 수 있는 
표준 분석 서버 템플릿입니다.

[agency-ai-engineer]: 시계열 데이터(음성, 보충 센서)를 수신하고 
치매 예측 지표를 추출하는 핵심 로직이 위치하는 곳입니다.
"""

app = FastAPI(title="MemoryLink Analysis API")

class AnalysisResult(BaseModel):
    risk_score: float
    speech_rate: float
    vocabulary_diversity: float
    status: str
    message: str

@app.get("/")
async def root():
    return {"message": "MemoryLink Analysis Server is running"}

@app.post("/analyze/voice", response_model=AnalysisResult)
async def analyze_voice(file: UploadFile = File(...)):
    """
    음성 파일(.m4a, .wav)을 수신하여 인지 건강 상태를 분석합니다.
    실제 구현 시에는 Whisper(STT) 및 특정 분석 알고리즘이 적용됩니다.
    """
    
    # [agency-ai-engineer]: 
    # 1. 파일 저장 또는 메모리 로드
    # 2. Whisper 또는 STT를 통한 텍스트 변환
    # 3. 언어적/음향적 특징 추출 (TTR, 유창성 등)
    
    # 분석 시뮬레이션 (3초)
    time.sleep(2)
    
    # 가상 분석 데이터 생성
    risk_score = random.uniform(0.1, 0.4) # 낮은 위험도
    speech_rate = random.uniform(140.0, 160.0) # 단어/분 (정상 범위)
    vocabulary_diversity = random.uniform(0.75, 0.9) # TTR (정상 범위)
    
    return AnalysisResult(
        risk_score=risk_score,
        speech_rate=speech_rate,
        vocabulary_diversity=vocabulary_diversity,
        status="success",
        message="분석이 성공적으로 완료되었습니다."
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
