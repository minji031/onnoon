# tests/test_auth.py
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_user_success():
    """회원가입 성공 테스트"""
    response = client.post(
        "/register",
        json={"email": "test@example.com", "password": "password123", "name": "Test User"},
    )
    assert response.status_code == 201
    assert response.json()["email"] == "test@example.com"

def test_create_user_duplicate_email():
    """이메일 중복 시 회원가입 실패 테스트"""
    # 위 테스트에서 이미 생성한 이메일로 다시 시도
    response = client.post(
        "/register",
        json={"email": "test@example.com", "password": "password123", "name": "Another User"},
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Email already registered"

def test_login_success():
    """로그인 성공 및 토큰 발급 테스트"""
    response = client.post(
        "/login",
        data={"username": "test@example.com", "password": "password123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"