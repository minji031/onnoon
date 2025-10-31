import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 프로젝트 모듈 임포트
from .database import engine, Base
from .logging_config import setup_logging
from .routers import auth, users, fatigue 


# 서버 시작 시 데이터베이스에 테이블 생성
Base.metadata.create_all(bind=engine)

# --- FastAPI 앱 설정 ---
app = FastAPI()

# --- 로깅 설정 ---
setup_logging()
logger = logging.getLogger(__name__)

# --- 이벤트 핸들러 ---
@app.on_event("startup")
async def startup_event():
    """애플리케이션이 시작될 때 실행됩니다."""
    logger.info("Application startup...")

# --- 미들웨어 설정 ---
origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    # (나중에 여기에 프론트엔드 '라이브 주소'도 추가)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"http://localhost(:\d+)?"
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 라우터 포함 ---
# 👇 [수정] prefix="/api" 부분을 모두 삭제합니다!
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(fatigue.router)

# --- 기본 API ---
@app.get("/")
def read_root():
    """서버가 살아있는지 확인하는 기본 경로"""
    logger.info("Root path was accessed.")
    return {"message": "Welcome to the Onnoon-Care API"}