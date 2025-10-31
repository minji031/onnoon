# app/schemas.py

from pydantic import BaseModel, EmailStr
from datetime import datetime

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
        # Pydantic V2 호환을 위해 orm_mode 대신 사용
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

# --- 진단 기록 관련 스키마 ---

class EyeData(BaseModel):
    """(AI 연동 전) 임시 입력 스키마"""
    blink_speed: float
    iris_dilation: float
    eye_movement_pattern: str

class FatigueResult(BaseModel):
    """진단 직후 결과를 보여주기 위한 응답 스키마"""
    user_id: int
    fatigue_score: float
    fatigue_grade: str
    created_at: datetime

    # 👇 [수정] Config 클래스를 여기에 추가합니다!
    class Config:
        from_attributes = True

class Record(BaseModel):
    """과거 진단 기록 전체를 조회하기 위한 응답 스키마"""
    id: int
    user_id: int
    fatigue_score: float
    blink_speed: float
    iris_dilation: float
    eye_movement_pattern: str
    created_at: datetime
    
    # 👇 "status" 필드가 있는지 확인합니다.
    status: str | None = None  

    class Config:
        # Pydantic V2 호환을 위해 orm_mode 대신 사용
        from_attributes = True