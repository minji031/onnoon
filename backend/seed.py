# seed.py

from faker import Faker
import random
from app import models, database, security

# app 폴더 밖에서 실행되므로, app 모듈을 임포트 할 수 있도록 경로 설정이 필요할 수 있습니다.
# 아래 코드는 app 폴더를 파이썬 경로에 추가합니다.
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

db = database.SessionLocal()
fake = Faker()

print("Seeding database...")

try:
    # 5명의 가상 사용자 생성
    for _ in range(5):
        # 👇 비밀번호를 임의의 문자열이 아닌, "password123"으로 고정합니다.
        hashed_password = security.get_password_hash("password123")

        user = models.User(
            name=fake.name(),
            email=fake.unique.email(),
            hashed_password=hashed_password
        )
        db.add(user)
        db.commit()

        # 👇 [수정] 이 부분을 통째로 교체하세요.
        # 각 사용자별 20개의 진단 기록 생성
        for _ in range(20):
            score = random.uniform(1.0, 5.0)

            # status 값을 가짜로 만듭니다.
            status_text = "양호함 😊" if score < 3.5 else "주의 필요 😐"

            record = models.EyeFatigueRecord(
                user_id=user.id,
                fatigue_score=score,

                # "status" 값 추가!
                status=status_text,

                # (예전 컬럼들은 일단 그대로 둡니다.)
                blink_speed=random.uniform(0.5, 3.0),
                iris_dilation=random.uniform(2.0, 8.0),
                eye_movement_pattern=random.choice(["smooth", "saccadic", "erratic"])
            )
            db.add(record)
        db.commit()

    print("Seeding complete.")
finally:
    db.close()