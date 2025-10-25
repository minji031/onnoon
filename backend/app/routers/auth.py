# app/routers/auth.py

import logging # 1. logging 임포트 추가
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from .. import database, schemas, models, security

# 2. 로거 설정 추가 (파일 상단 적절한 위치에)
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/auth", # 3. prefix="/api/auth" 추가 (이전에 빠졌던 부분)
    tags=['Authentication']
)

@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    logger.info(f"회원가입 요청 받음: {user.email}") # 로그 추가

    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        logger.warning(f"이미 존재하는 이메일: {user.email}") # 로그 추가
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    if len(user.password) < 8:
        logger.warning(f"비밀번호 길이 부족: {user.email}") # 로그 추가
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Password must be at least 8 characters")

    hashed_password = security.get_password_hash(user.password)
    new_user = models.User(email=user.email, name=user.name, hashed_password=hashed_password)
    
    logger.info(f"DB에 사용자 추가 시도: {user.email}") # 로그 추가
    db.add(new_user)
    
    # 👇 4. db.commit() 부분을 try...except로 감싸고 로그 추가
    try:
        db.commit() # 👈 여기가 문제일 가능성!
        logger.info(f"DB 커밋 성공: {user.email}") # 커밋 성공 로그
    except Exception as e:
        logger.error(f"DB 커밋 실패: {user.email}, 오류: {e}") # 커밋 실패 로그!
        db.rollback() # 오류 발생 시 변경사항 되돌리기
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Database commit failed")

    db.refresh(new_user)
    logger.info(f"회원가입 성공 및 응답: {user.email}") # 로그 추가
    return new_user

@router.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    
    access_token = security.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}