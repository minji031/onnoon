from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from .. import schemas, models, security, database

router = APIRouter(
    prefix="/api/users",  # 👈 '/users' -> '/api/users'로 수정!
    tags=['Users']
)

@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(security.get_current_user)):
    """
    현재 로그인된 사용자의 정보를 반환합니다.
    요청 시 헤더에 "Authorization: Bearer <토큰값>"이 포함되어야 합니다.
    """
    return current_user