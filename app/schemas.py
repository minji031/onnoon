# app/schemas.py

from pydantic import BaseModel, EmailStr
from datetime import datetime  # 1. datetime 임포트 추가

# --- 사용자 및 인증 관련 스키마 ---
class UserCreate(BaseModel):
    email: EmailStr
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

# --- 진단 기록 관련 스키마 ---

class EyeData(BaseModel):
    """눈 피로도 기록 생성을 위한 요청 스키마 (AI -> 백엔드)"""
    blink_speed: float
    iris_dilation: float
    eye_movement_pattern: str

class FatigueResult(BaseModel):
    """진단 직후 결과를 보여주기 위한 응답 스키마"""
    user_id: int
    fatigue_score: float
    fatigue_grade: str
    created_at: datetime  # 2. str -> datetime 타입으로 통일

# 3. 들여쓰기 수정: FatigueResult 클래스 밖으로 빼냈습니다.
class Record(BaseModel):
    """과거 진단 기록 전체를 조회하기 위한 응답 스키마"""
    id: int
    user_id: int
    fatigue_score: float
    blink_speed: float
    iris_dilation: float
    eye_movement_pattern: str
    created_at: datetime

    class Config:
        orm_mode = True