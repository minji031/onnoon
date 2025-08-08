from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.database import SessionLocal, engine
from app.models import Base, User, EyeFatigueRecord
from typing import List
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# ✅ CORS 설정
origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://your-teammate-ip:3000"
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ DB 테이블 생성
Base.metadata.create_all(bind=engine)

# ✅ 기본 루트
@app.get("/")
def read_root():
    return {"message": "Welcome to the API"}

# ✅ Pydantic 모델 정의
class EyeData(BaseModel):
    blink_speed: float
    iris_dilation: float
    eye_movement_pattern: str

class UserCreate(BaseModel):
    name: str
    email: str

class FatigueResult(BaseModel):
    user_id: int
    fatigue_score: float
    fatigue_grade: str
    created_at: str

# ✅ DB 세션
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ✅ 사용자 생성
@app.post("/users/")
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = User(name=user.name, email=user.email)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# ✅ 피로도 계산 및 저장
@app.post("/api/eye-fatigue")
def calculate_eye_fatigue(data: EyeData, db: Session = Depends(get_db)):
    fatigue_score = data.blink_speed * 0.5 + data.iris_dilation * 0.3
    db_record = EyeFatigueRecord(user_id=1, fatigue_score=fatigue_score)
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return {"fatigue_score": fatigue_score}

# ✅ AI 진단 결과 조회 (피로도 등급 포함)
@app.get(
    "/api/eye-fatigue/result/{user_id}",
    response_model=FatigueResult,
    summary="AI 진단 결과 조회",
    description="해당 사용자의 최근 눈 피로도 점수를 조회하고, 점수에 따라 피로 등급(좋음/보통/주의)을 반환합니다."
)
def get_fatigue_result(user_id: int, db: Session = Depends(get_db)):
    record = db.query(EyeFatigueRecord).filter(
        EyeFatigueRecord.user_id == user_id
    ).order_by(EyeFatigueRecord.created_at.desc()).first()

    if not record:
        raise HTTPException(status_code=404, detail="No record found")

    # 🧠 점수 등급화
    score = record.fatigue_score
    if score < 2.5:
        grade = "좋음"
    elif score < 4.0:
        grade = "보통"
    else:
        grade = "주의"

    return {
        "user_id": record.user_id,
        "fatigue_score": score,
        "fatigue_grade": grade,
        "created_at": str(record.created_at)
    }

# ✅ 사용자 전체 조회
@app.get("/users/", response_model=List[UserCreate])
def get_users(db: Session = Depends(get_db)):
    return db.query(User).all()

# ✅ 사용자 1명 조회
@app.get("/users/{user_id}")
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# ✅ 피로도 기록 전체 조회
@app.get("/users/{user_id}/records")
def get_eye_fatigue_records(user_id: int, db: Session = Depends(get_db)):
    records = db.query(EyeFatigueRecord).filter(EyeFatigueRecord.user_id == user_id).all()
    return records

# ✅ 최근 피로도 기록 조회
@app.get("/users/{user_id}/records/latest")
def get_latest_record(user_id: int, db: Session = Depends(get_db)):
    record = db.query(EyeFatigueRecord).filter(EyeFatigueRecord.user_id == user_id).order_by(EyeFatigueRecord.created_at.desc()).first()
    if not record:
        raise HTTPException(status_code=404, detail="No record found")
    return record

# ✅ main 실행 (로컬 테스트용)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
