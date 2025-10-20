from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """
    .env 파일에서 환경 변수를 읽어오는 설정 클래스
    """
    database_url: str
    secret_key: str
    algorithm: str

    class Config:
        env_file = ".env"

# 👇 이 부분이 settings 변수를 실제로 만드는 가장 중요한 코드입니다.
settings = Settings()