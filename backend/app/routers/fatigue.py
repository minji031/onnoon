from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

# database, schemas, models, security를 정확히 임포트합니다.
from .. import database, schemas, models, security

router = APIRouter(
    prefix="/api/eye-fatigue", # prefix가 /api/eye-fatigue 인지 확인
    tags=['Fatigue']
)

@router.post("/", response_model=schemas.Record, summary="눈 피로도 기록 생성")
def create_fatigue_record(
    data: schemas.EyeData, # AI 연동 전 임시 입력 스키마
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    (AI 연동 전 임시)
    현재 로그인된 사용자의 눈 피로도 데이터를 계산하고 저장합니다.
    """
    # 임시 계산 로직
    fatigue_score = data.blink_speed * 0.5 + data.iris_dilation * 0.3

    # seed.py와 유사하게 status 임시 생성
    status_text = "양호함 😊" if fatigue_score < 3.5 else "주의 필요 😐"

    db_record = models.EyeFatigueRecord(
        user_id=current_user.id,
        fatigue_score=fatigue_score,
        status=status_text, # status 값 추가
        blink_speed=data.blink_speed,
        iris_dilation=data.iris_dilation,
        eye_movement_pattern=data.eye_movement_pattern
    )
    db.add(db_record)
    db.commit()
    db.refresh(db_record) # DB에서 생성된 id, created_at 등을 포함하여 반환
    return db_record

@router.get("/result", response_model=schemas.FatigueResult, summary="최근 내 진단 결과 조회")
def get_my_latest_fatigue_result(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    현재 로그인된 사용자의 가장 최근 눈 피로도 진단 결과를 반환합니다.
    """
    record = db.query(models.EyeFatigueRecord).filter(
        models.EyeFatigueRecord.user_id == current_user.id
    ).order_by(models.EyeFatigueRecord.created_at.desc()).first()

    if not record:
        raise HTTPException(status_code=404, detail="진단 기록을 찾을 수 없습니다.")

    # [수정] DB에 저장된 status 값을 사용합니다.
    grade = record.status if record.status else "분석중" 

    score = record.fatigue_score if record.fatigue_score is not None else 0.0

    return schemas.FatigueResult( 
        user_id=record.user_id,
        fatigue_score=score,
        fatigue_grade=grade, # status 값으로 대체
        created_at=record.created_at
    )

@router.get("/history", response_model=List[schemas.Record], summary="내 모든 진단 기록 조회")
def get_my_fatigue_history(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    현재 로그인된 사용자의 모든 과거 눈 피로도 진단 기록을 시간순으로 반환합니다.
    """
    records = db.query(models.EyeFatigueRecord).filter(
        models.EyeFatigueRecord.user_id == current_user.id
    ).order_by(models.EyeFatigueRecord.created_at.desc()).all()

    return records

# 👇 [추가] 프론트엔드가 요청한 '상세 조회 API'
@router.get("/{record_id}", response_model=schemas.Record, summary="특정 진단 기록 상세 조회")
def get_specific_record(
    record_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    id를 기준으로 특정 진단 기록 1개를 조회합니다.
    """
    record = db.query(models.EyeFatigueRecord).filter(
        models.EyeFatigueRecord.id == record_id,
        models.EyeFatigueRecord.user_id == current_user.id # 본인 기록만 조회 권한 확인
    ).first()

    if not record:
        raise HTTPException(status_code=404, detail="해당 기록을 찾을 수 없거나 권한이 없습니다.")

    return record