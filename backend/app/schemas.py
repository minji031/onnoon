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
    """눈 피로도 기록 생성을 위한 요청 스키마 (AI -> 백엔드)"""
    blink_speed: float
    iris_dilation: float
    eye_movement_pattern: str

class FatigueResult(BaseModel):
    """진단 직후 결과를 보여주기 위한 응답 스키마"""
    user_id: int
    fatigue_score: float
    fatigue_grade: str
    created_at: datetime

    # 👇 [수정] 500 오류 해결을 위해 Config 클래스를 추가합니다!
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
    status: str | None = None

    class Config:
        from_attributes = True