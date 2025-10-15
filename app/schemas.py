# app/schemas.py
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    email: EmailStr  # 이메일 형식 자동 검증
    password: str
    name: str

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    name: str
    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class EyeData(BaseModel):
    """눈 피로도 기록 생성을 위한 요청 스키마"""
    blink_speed: float
    iris_dilation: float
    eye_movement_pattern: str

class FatigueResult(BaseModel):
    """진단 결과 조회를 위한 응답 스키마"""
    user_id: int
    fatigue_score: float
    fatigue_grade: str
    created_at: str 