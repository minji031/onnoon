# app/schemas.py

from pydantic import BaseModel, EmailStr
from datetime import datetime

# --- (UserCreate, UserResponse, Token, EyeData는 그대로) ---

class FatigueResult(BaseModel):
    """진단 직후 결과를 보여주기 위한 응답 스키마"""
    user_id: int
    fatigue_score: float
    fatigue_grade: str
    created_at: datetime

    # 👇 [수정] 이 Config 클래스를 추가해야 합니다!
    class Config:
        from_attributes = True

class Record(BaseModel):
    """과거 진단 기록 전체를 조회하기 위한 응답 스키마"""
    id: int
    user_id: int
    # ... (다른 Record 필드들) ...
    status: str | None = None

    class Config:
        from_attributes = True