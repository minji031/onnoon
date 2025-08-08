# app/models/users.py

from sqlalchemy import Column, Integer, Float, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)

class EyeFatigueRecord(Base):
    __tablename__ = 'eye_fatigue_records'

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, nullable=False)
    fatigue_score = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
