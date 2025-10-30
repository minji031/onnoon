from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
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
    
    # 👇 [추가] 프론트엔드 연동을 위한 'status' 컬럼
    status = Column(String(50), nullable=True) 
    
    # (다른 컬럼들은 nullable=True로 변경하여 유연성을 높였습니다)
    blink_speed = Column(Float, nullable=True)ㅎ
    iris_dilation = Column(Float, nullable=True)
    eye_movement_pattern = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="records")