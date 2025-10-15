from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from .. import database, schemas, models, security

router = APIRouter(
    prefix="/api/eye-fatigue",
    tags=['Fatigue']
)

@router.post("/", summary="눈 피로도 기록 생성")
def create_fatigue_record(
    data: schemas.EyeData, 
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(security.get_current_user)
):
    """
    현재 로그인된 사용자의 눈 피로도 데이터를 계산하고 저장합니다.
    """
    fatigue_score = data.blink_speed * 0.5 + data.iris_dilation * 0.3
    
    db_record = models.EyeFatigueRecord(
        user_id=current_user.id,  # 👈 user_id=1 대신 로그인된 사용자 ID를 사용합니다.
        fatigue_score=fatigue_score,
        **data.dict()
    )
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
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

    score = record.fatigue_score
    if score < 2.5:
        grade = "좋음"
    elif score < 4.0:
        grade = "보통"
    else:
        grade = "주의"

    return {
        "user_id": record.user_id,
        "fatigue_score": score,
        "fatigue_grade": grade,
        "created_at": str(record.created_at)
    }