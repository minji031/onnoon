
import logging

def setup_logging():
    """
    애플리케이션 전체의 로깅을 설정합니다.
    """
    # 기본 로거 설정
    logging.basicConfig(
        level=logging.INFO,  # INFO 레벨 이상의 로그만 출력
        format="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    # uvicorn과 fastapi 로거 가져오기
    uvicorn_logger = logging.getLogger("uvicorn.access")
    fastapi_logger = logging.getLogger("fastapi")

    # uvicorn과 fastapi 로그 레벨 설정 (필요 시 DEBUG로 변경)
    uvicorn_logger.setLevel(logging.INFO)
    fastapi_logger.setLevel(logging.INFO)
