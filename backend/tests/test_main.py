from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_root():
    """루트 경로('/')가 올바른 메시지를 반환하는지 테스트"""
    response = client.get("/")
    assert response.status_code == 200
    # 👇 응답 메시지를 현재 버전에 맞게 수정했습니다.
    assert response.json() == {"message": "Welcome to the Onnoon-Care API"}

# 참고: 나머지 오래된 테스트들은 이제 test_auth.py와 fatigue API 테스트에서
# 더 정확하게 다루므로, 여기서는 가장 기본적인 루트 경로 테스트만 남겨둡니다.