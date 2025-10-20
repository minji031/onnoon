from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from ..database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    # 👈 1. 로그인 기능을 위한 비밀번호 필드 추가
    hashed_password = Column(String, nullable=False) 

    records = relationship("EyeFatigueRecord", back_populates="owner")


class EyeFatigueRecord(Base):
    __tablename__ = "eye_fatigue_records"

    id = Column(Integer, primary_key=True, index=True)
    # 👈 2. User 테이블과 관계 설정
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False) 
    
    # 👈 3. 오류를 해결하기 위한 fatigue_score 필드 추가
    fatigue_score = Column(Float, nullable=True) 
    
    blink_speed = Column(Float)
    iris_dilation = Column(Float)
    eye_movement_pattern = Column(String(50))
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="records")