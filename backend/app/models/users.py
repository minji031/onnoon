from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
# 👇 1. 'func'를 임포트합니다.
from sqlalchemy.sql import func 
# database.py 파일이 models 폴더 밖에 app 폴더에 있으므로 ..database 가 맞습니다.
from ..database import Base 

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False) 

    records = relationship("EyeFatigueRecord", back_populates="owner")


class EyeFatigueRecord(Base):
    __tablename__ = "eye_fatigue_records"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    fatigue_score = Column(Float, nullable=True) 
    
    status = Column(String(50), nullable=True) 
    
    blink_speed = Column(Float, nullable=True)
    iris_dilation = Column(Float, nullable=True)
    eye_movement_pattern = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", back_populates="records")