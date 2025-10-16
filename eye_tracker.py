import cv2
import mediapipe as mp
import time
import math
import json  # << JSON 라이브러리 추가
from datetime import datetime  # << 시간 기록을 위한 라이브러리 추가

# --- 설정값 (튜닝을 위해 이 값을 조정하세요) ---
# EAR 임계값: 이 값보다 작아지면 눈을 감은 것으로 판단
EAR_THRESHOLD = 0.20
# 연속 프레임: EAR 임계값보다 낮은 상태가 이 프레임 수만큼 지속되어야 깜빡임으로 인정
EAR_CONSEC_FRAMES = 3
# 시선 임계값: 홍채의 상대적 위치가 이 값보다 작으면 왼쪽, 크면 오른쪽으로 판단
GAZE_THRESHOLD_LEFT = 0.40   # << 기존 0.35에서 수정
GAZE_THRESHOLD_RIGHT = 0.60  # << 기존 0.65에서 수정
# 분석 주기 (초): 이 시간마다 피로도를 계산하고 출력
ANALYSIS_PERIOD_SECONDS = 10
OUTPUT_FILENAME = "fatigue_log.json"

# --- MediaPipe Face Mesh 초기화 ---
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,  # 눈 주변 랜드마크 정밀도 향상
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# --- 눈, 홍채 랜드마크 인덱스 정의 ---
LEFT_EYE = [33, 160, 158, 133, 153, 144]
RIGHT_EYE = [362, 385, 387, 263, 373, 380]
LEFT_IRIS_CENTER = 473
RIGHT_IRIS_CENTER = 468


class EyeFatigueMonitor:
    """
    눈의 피로도를 실시간으로 추적하고 분석하는 클래스.
    - 눈 깜빡임, 초점 시간 등을 측정하여 피로도 점수를 계산합니다.
    """

    def __init__(self, ear_threshold, analysis_period):
        """모니터 초기화"""
        # 설정값
        self.ear_threshold = ear_threshold
        self.analysis_period = analysis_period

        # 상태 변수
        self.is_blinking = False  # 현재 깜빡이는 중인지 여부
        self.blink_frame_counter = 0  # << 이 줄을 추가하세요
        self.is_focused = False   # 현재 정면을 응시하며 집중하는 중인지 여부

        # 데이터 누적 변수
        self.blink_count = 0
        self.focus_durations = []
        self.current_focus_start_time = None
        self.gaze_direction_latest = "CENTER"

        # 시간 측정 변수
        self.analysis_start_time = time.time()

    def _euclidean(self, p1, p2):
        """두 점 사이의 유클리드 거리를 계산합니다."""
        return math.hypot(p2[0] - p1[0], p2[1] - p1[1])

    def _get_ear(self, eye_landmarks):
        """눈 랜드마크로부터 EAR(Eye Aspect Ratio) 값을 계산합니다."""
        A = self._euclidean(eye_landmarks[1], eye_landmarks[5])
        B = self._euclidean(eye_landmarks[2], eye_landmarks[4])
        C = self._euclidean(eye_landmarks[0], eye_landmarks[3])
        return (A + B) / (2.0 * C)

    def process_frame(self, frame):
        """
        입력된 비디오 프레임을 처리하여 눈 관련 지표를 업데이트합니다.
        """
        # 얼굴 랜드마크 감지
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = face_mesh.process(rgb)

        if result.multi_face_landmarks:
            for face_landmarks in result.multi_face_landmarks:
                h, w, _ = frame.shape

                left_eye_coords = [(int(face_landmarks.landmark[i].x * w), int(face_landmarks.landmark[i].y * h)) for i in LEFT_EYE]
                right_eye_coords = [(int(face_landmarks.landmark[i].x * w), int(face_landmarks.landmark[i].y * h)) for i in RIGHT_EYE]
                ear = (self._get_ear(left_eye_coords) + self._get_ear(right_eye_coords)) / 2.0

                # 눈 위에 랜드마크 그리기
                for (x, y) in left_eye_coords + right_eye_coords:
                    cv2.circle(frame, (x, y), 2, (0, 255, 0), -1)

                # 1. 눈 깜빡임 감지 (연속 프레임 확인 로직 적용)
                if ear < self.ear_threshold:
                    self.blink_frame_counter += 1  # 눈 감은 프레임 카운트 증가
                else:
                    # 눈을 떴을 때, 연속 프레임 카운터가 기준을 넘었다면
                    if self.blink_frame_counter >= EAR_CONSEC_FRAMES:
                        self.blink_count += 1  # 깜빡임 횟수 1 증가
                    
                    self.blink_frame_counter = 0  # 눈을 떴으니 카운터 초기화

                # 2. 시선 방향 추정 (Gaze Direction)
                eye_left_lm = face_landmarks.landmark[LEFT_EYE[0]]
                eye_right_lm = face_landmarks.landmark[LEFT_EYE[3]]
                iris_center_lm = face_landmarks.landmark[LEFT_IRIS_CENTER]

                # 시선 방향 계산 시 0으로 나누는 오류 방지
                eye_width = (eye_right_lm.x - eye_left_lm.x)
                if eye_width != 0:
                    relative_iris_pos = (iris_center_lm.x - eye_left_lm.x) / eye_width
                    
                    # --- 여기서 GAZE 임계값을 사용하도록 수정 ---
                    if relative_iris_pos < GAZE_THRESHOLD_LEFT:
                        self.gaze_direction_latest = "LEFT"
                    elif relative_iris_pos > GAZE_THRESHOLD_RIGHT:
                        self.gaze_direction_latest = "RIGHT"
                    else:
                        self.gaze_direction_latest = "CENTER"

                    # --- 이 부분을 추가하여 현재 시선 위치 값(Gaze Pos) 표시 ---
                    cv2.putText(frame, f"Gaze Pos: {relative_iris_pos:.2f}", (30, 120),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 255), 2)
                   
                # --- 이 부분을 추가하여 현재 EAR 수치 표시 ---
                cv2.putText(frame, f"EAR: {ear:.2f}", (30, 90), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)

        # 3. 초점 시간 측정 (Focus Time)
        if self.gaze_direction_latest == "CENTER":
            if not self.is_focused:
                self.current_focus_start_time = time.time()
                self.is_focused = True
        else:
            if self.is_focused:
                focus_duration = time.time() - self.current_focus_start_time
                self.focus_durations.append(focus_duration)
                self.is_focused = False
                self.current_focus_start_time = None

                

    def run_analysis(self):
        """
        설정된 분석 주기가 되면 피로도를 계산하고 결과를 출력합니다.
        """
        if time.time() - self.analysis_start_time >= self.analysis_period:
            # --- 1. 핵심 지표 계산 ---
            bpm = self.blink_count  # 분석 주기가 60초이므로, 누적된 횟수가 BPM

            if self.is_focused:
                focus_duration = time.time() - self.current_focus_start_time
                self.focus_durations.append(focus_duration)
            
            max_focus_time = max(self.focus_durations) if self.focus_durations else 0

            print(f"\n--- [ {self.analysis_period}초 분석 결과 ] ---")
            print(f"분당 깜빡임 (BPM): {bpm} 회")
            print(f"최대 초점 유지 시간: {max_focus_time:.2f} 초")

            # --- 2. 지표 정규화 (점수 변환) ---
            if bpm <= 5: blink_score = 100
            elif bpm <= 10: blink_score = 70
            elif bpm <= 15: blink_score = 30
            else: blink_score = 0

            if max_focus_time >= 90: focus_score = 100
            elif max_focus_time >= 60: focus_score = 70
            elif max_focus_time >= 30: focus_score = 30
            else: focus_score = 0
            
            # --- 3. 최종 피로도 점수 계산 ---
            total_fatigue_score = (blink_score * 0.5) + (focus_score * 0.4)
            
            print(f"피로도 점수: {total_fatigue_score:.1f} / 100")
            
            # --- 4. 결과 해석 ---
            if total_fatigue_score > 80: fatigue_status = "매우 나쁨 😵"
            elif total_fatigue_score > 50: fatigue_status = "주의 필요 😐"
            else: fatigue_status = "양호함 😊"
            
            print(f"현재 눈 상태: {fatigue_status}")
            print("--------------------------\n")

            # 1. 저장할 데이터를 딕셔너리 형태로 만듭니다.
            new_log_data = {
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "bpm": bpm,
                "max_focus_time": round(max_focus_time, 2),
                "fatigue_score": round(total_fatigue_score, 1),
                "fatigue_status": fatigue_status
            }

            # 2. 기존 로그 파일을 불러옵니다. 파일이 없으면 새로 시작합니다.
            try:
                with open(OUTPUT_FILENAME, 'r', encoding='utf-8') as f:
                    logs = json.load(f)
            except FileNotFoundError:
                logs = []
            
            # 3. 새로운 로그를 추가하고 파일에 다시 저장합니다.
            logs.append(new_log_data)
            with open(OUTPUT_FILENAME, 'w', encoding='utf-8') as f:
                json.dump(logs, f, ensure_ascii=False, indent=4)

            # --- 다음 분석을 위해 변수 초기화 ---
            self.analysis_start_time = time.time()
            self.blink_count = 0
            self.focus_durations = []
            # is_blinking과 is_focused는 연속성을 위해 초기화하지 않음


if __name__ == "__main__":
    cap = cv2.VideoCapture(0)
    monitor = EyeFatigueMonitor(ear_threshold=EAR_THRESHOLD, analysis_period=ANALYSIS_PERIOD_SECONDS)

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frame = cv2.flip(frame, 1)

        # 프레임 처리 및 눈 상태 업데이트
        monitor.process_frame(frame)
        
        # 주기적으로 피로도 분석 실행
        monitor.run_analysis()

        # 화면에 프레임 표시
        cv2.imshow("Eye Fatigue Monitor", frame)
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()
