from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

# database, schemas, models, security를 정확히 임포트합니다.
from .. import database, schemas, models, security

router = APIRouter(
    prefix="/api/fatigue", # prefix 수정: eye-fatigue
    tags=['Fatigue'] # 태그 이름 수정 (대소문자 일관성)
)

@router.post("/", response_model=schemas.Record, summary="눈 피로도 기록 생성") # 응답 모델 수정: 생성 후 Record 반환
def create_fatigue_record(
    data: schemas.FatigueDataInput, # AI 연동 전 임시 입력 스키마
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    현재 로그인된 사용자의 눈 피로도 데이터를 계산하고 저장합니다. (AI 연동 전 임시)
    """
    # 임시 계산 로직 (AI 연동 시 변경 필요)
    # fatigue_score = data.blink_speed * 0.5 + data.iris_dilation * 0.3

    # seed.py와 유사하게 status 임시 생성
    # status_text = "양호함 😊" if fatigue_score < 3.5 else "주의 필요 😐"

    # EyeData에 없는 컬럼들도 models.py에 맞게 추가
    db_record = models.EyeFatigueRecord(
        user_id=current_user.id,
        
        fatigue_score=data.health_score,  # AI의 health_score -> DB의 fatigue_score
        status=data.status,             # AI의 status -> DB의 status
        blink_speed=data.bpm,           # AI의 bpm -> DB의 blink_speed
        
        # AI가 보내는 max_stable_gaze_time을 eye_movement_pattern 칸에 저장
        eye_movement_pattern=f"Gaze_Time: {data.max_stable_gaze_time}",
        
        # AI가 안 보내는 값 (기본값 0.0으로 채움)
        iris_dilation=0.0
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

    # models.py에 status를 추가했으므로, record.status를 사용합니다.
    grade = record.status if record.status else "분석중" # DB에 status가 있으면 사용

    # fatigue_score가 None일 수 있으므로 처리 추가
    score = record.fatigue_score if record.fatigue_score is not None else 0.0

    return schemas.FatigueResult( # 스키마를 사용하여 응답 구조 보장
        user_id=record.user_id,
        fatigue_score=score,
        fatigue_grade=grade, # status 값으로 대체
        created_at=record.created_at # datetime 객체 그대로 반환 (FastAPI가 처리)
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

    # 기록이 없을 때 빈 리스트 []를 반환하는 것이 일반적입니다.
    # if not records:
    #     raise HTTPException(status_code=404, detail="진단 기록을 찾을 수 없습니다.")

    return records

# 👇 [수정] 이 함수가 빠졌습니다! 파일 맨 아래에 새로 추가하세요!
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