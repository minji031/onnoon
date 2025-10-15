<<<<<<< HEAD
import cv2
import mediapipe as mp
import time
import math

mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(refine_landmarks=True)

cap = cv2.VideoCapture(0)

LEFT_EYE = [33, 160, 158, 133, 153, 144]
RIGHT_EYE = [362, 385, 387, 263, 373, 380]

LEFT_IRIS_CENTER = 473
LEFT_EYE_LEFT = 33
LEFT_EYE_RIGHT = 133

RIGHT_IRIS_CENTER = 468
RIGHT_EYE_LEFT = 263
RIGHT_EYE_RIGHT = 362

def euclidean(p1, p2):
    return math.hypot(p2[0] - p1[0], p2[1] - p1[1])

def get_EAR(eye_landmarks):
    A = euclidean(eye_landmarks[1], eye_landmarks[5])
    B = euclidean(eye_landmarks[2], eye_landmarks[4])
    C = euclidean(eye_landmarks[0], eye_landmarks[3])
    return (A + B) / (2.0 * C)

blink_count = 0
frame_count = 0
start_time = time.time()

left_iris_dilation_latest = None
right_iris_dilation_latest = None
gaze_direction_latest = None

while True:
    ret, frame = cap.read()
    if not ret:
        break
    frame = cv2.flip(frame, 1)
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = face_mesh.process(rgb)

    if result.multi_face_landmarks:
        for face_landmarks in result.multi_face_landmarks:
            h, w, _ = frame.shape

            left_eye = [(int(face_landmarks.landmark[i].x * w), int(face_landmarks.landmark[i].y * h)) for i in LEFT_EYE]
            right_eye = [(int(face_landmarks.landmark[i].x * w), int(face_landmarks.landmark[i].y * h)) for i in RIGHT_EYE]

            left_ear = get_EAR(left_eye)
            right_ear = get_EAR(right_eye)
            ear = (left_ear + right_ear) / 2.0

            if ear < 0.25:
                blink_count += 1

            for (x, y) in left_eye + right_eye:
                cv2.circle(frame, (x, y), 2, (0, 255, 0), -1)

            try:
                # Iris dilation (left)
                left_iris = face_landmarks.landmark[LEFT_IRIS_CENTER]
                left_eye_left = face_landmarks.landmark[LEFT_EYE_LEFT]
                left_eye_right = face_landmarks.landmark[LEFT_EYE_RIGHT]

                left_iris_x, left_iris_y = int(left_iris.x * w), int(left_iris.y * h)
                left_eye_left_x, left_eye_left_y = int(left_eye_left.x * w), int(left_eye_left.y * h)
                left_eye_right_x, left_eye_right_y = int(left_eye_right.x * w), int(left_eye_right.y * h)

                left_eye_width = math.hypot(left_eye_right_x - left_eye_left_x, left_eye_right_y - left_eye_left_y)
                left_iris_to_left = math.hypot(left_iris_x - left_eye_left_x, left_iris_y - left_eye_left_y)
                left_iris_to_right = math.hypot(left_iris_x - left_eye_right_x, left_iris_y - left_eye_right_y)
                left_iris_radius = (left_iris_to_left + left_iris_to_right) / 2
                left_iris_dilation = left_iris_radius / left_eye_width

                # Iris dilation (right)
                right_iris = face_landmarks.landmark[RIGHT_IRIS_CENTER]
                right_eye_left = face_landmarks.landmark[RIGHT_EYE_LEFT]
                right_eye_right = face_landmarks.landmark[RIGHT_EYE_RIGHT]

                right_iris_x, right_iris_y = int(right_iris.x * w), int(right_iris.y * h)
                right_eye_left_x, right_eye_left_y = int(right_eye_left.x * w), int(right_eye_left.y * h)
                right_eye_right_x, right_eye_right_y = int(right_eye_right.x * w), int(right_eye_right.y * h)

                right_eye_width = math.hypot(right_eye_right_x - right_eye_left_x, right_eye_right_y - right_eye_left_y)
                right_iris_to_left = math.hypot(right_iris_x - right_eye_left_x, right_iris_y - right_eye_left_y)
                right_iris_to_right = math.hypot(right_iris_x - right_eye_right_x, right_iris_y - right_eye_right_y)
                right_iris_radius = (right_iris_to_left + right_iris_to_right) / 2
                right_iris_dilation = right_iris_radius / right_eye_width

                left_iris_dilation_latest = left_iris_dilation
                right_iris_dilation_latest = right_iris_dilation

                cv2.putText(frame, f"Left Iris Dilation: {left_iris_dilation:.2f}", (30, 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 100, 0), 2)
                cv2.putText(frame, f"Right Iris Dilation: {right_iris_dilation:.2f}", (30, 90),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 100, 255), 2)

                cv2.circle(frame, (left_iris_x, left_iris_y), 3, (255, 100, 0), -1)
                cv2.circle(frame, (right_iris_x, right_iris_y), 3, (0, 100, 255), -1)

                # Gaze direction
                eye_left = face_landmarks.landmark[LEFT_EYE_LEFT]
                eye_right = face_landmarks.landmark[LEFT_EYE_RIGHT]
                iris_center = face_landmarks.landmark[LEFT_IRIS_CENTER]

                relative_iris_pos = (iris_center.x - eye_left.x) / (eye_right.x - eye_left.x)

                if relative_iris_pos < 0.35:
                    gaze_direction = "왼쪽"
                elif relative_iris_pos > 0.65:
                    gaze_direction = "오른쪽"
                else:
                    gaze_direction = "정면"

                gaze_direction_latest = gaze_direction

                cv2.putText(frame, f"Gaze: {gaze_direction}", (30, 120),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

            except IndexError:
                pass

    frame_count += 1

    if time.time() - start_time >= 10:
        blink_speed = blink_count / 10
        print(f"Blink Speed: {blink_speed:.2f} blinks/sec")

        if left_iris_dilation_latest is not None and right_iris_dilation_latest is not None:
            print(f"Left Iris Dilation: {left_iris_dilation_latest:.2f}")
            print(f"Right Iris Dilation: {right_iris_dilation_latest:.2f}")
        if gaze_direction_latest is not None:
            print(f"Gaze Direction: {gaze_direction_latest}")

        blink_count = 0
        start_time = time.time()

    cv2.imshow("Eye Tracker", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()

=======
import cv2
import mediapipe as mp
import time
import math

mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(refine_landmarks=True)

cap = cv2.VideoCapture(0)

LEFT_EYE = [33, 160, 158, 133, 153, 144]
RIGHT_EYE = [362, 385, 387, 263, 373, 380]

LEFT_IRIS_CENTER = 473
LEFT_EYE_LEFT = 33
LEFT_EYE_RIGHT = 133

RIGHT_IRIS_CENTER = 468
RIGHT_EYE_LEFT = 263
RIGHT_EYE_RIGHT = 362

def euclidean(p1, p2):
    return math.hypot(p2[0] - p1[0], p2[1] - p1[1])

def get_EAR(eye_landmarks):
    A = euclidean(eye_landmarks[1], eye_landmarks[5])
    B = euclidean(eye_landmarks[2], eye_landmarks[4])
    C = euclidean(eye_landmarks[0], eye_landmarks[3])
    return (A + B) / (2.0 * C)

blink_count = 0
frame_count = 0
start_time = time.time()

left_iris_dilation_latest = None
right_iris_dilation_latest = None
gaze_direction_latest = None

while True:
    ret, frame = cap.read()
    if not ret:
        break
    frame = cv2.flip(frame, 1)
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = face_mesh.process(rgb)

    if result.multi_face_landmarks:
        for face_landmarks in result.multi_face_landmarks:
            h, w, _ = frame.shape

            left_eye = [(int(face_landmarks.landmark[i].x * w), int(face_landmarks.landmark[i].y * h)) for i in LEFT_EYE]
            right_eye = [(int(face_landmarks.landmark[i].x * w), int(face_landmarks.landmark[i].y * h)) for i in RIGHT_EYE]

            left_ear = get_EAR(left_eye)
            right_ear = get_EAR(right_eye)
            ear = (left_ear + right_ear) / 2.0

            if ear < 0.25:
                blink_count += 1

            for (x, y) in left_eye + right_eye:
                cv2.circle(frame, (x, y), 2, (0, 255, 0), -1)

            try:
                # Iris dilation (left)
                left_iris = face_landmarks.landmark[LEFT_IRIS_CENTER]
                left_eye_left = face_landmarks.landmark[LEFT_EYE_LEFT]
                left_eye_right = face_landmarks.landmark[LEFT_EYE_RIGHT]

                left_iris_x, left_iris_y = int(left_iris.x * w), int(left_iris.y * h)
                left_eye_left_x, left_eye_left_y = int(left_eye_left.x * w), int(left_eye_left.y * h)
                left_eye_right_x, left_eye_right_y = int(left_eye_right.x * w), int(left_eye_right.y * h)

                left_eye_width = math.hypot(left_eye_right_x - left_eye_left_x, left_eye_right_y - left_eye_left_y)
                left_iris_to_left = math.hypot(left_iris_x - left_eye_left_x, left_iris_y - left_eye_left_y)
                left_iris_to_right = math.hypot(left_iris_x - left_eye_right_x, left_iris_y - left_eye_right_y)
                left_iris_radius = (left_iris_to_left + left_iris_to_right) / 2
                left_iris_dilation = left_iris_radius / left_eye_width

                # Iris dilation (right)
                right_iris = face_landmarks.landmark[RIGHT_IRIS_CENTER]
                right_eye_left = face_landmarks.landmark[RIGHT_EYE_LEFT]
                right_eye_right = face_landmarks.landmark[RIGHT_EYE_RIGHT]

                right_iris_x, right_iris_y = int(right_iris.x * w), int(right_iris.y * h)
                right_eye_left_x, right_eye_left_y = int(right_eye_left.x * w), int(right_eye_left.y * h)
                right_eye_right_x, right_eye_right_y = int(right_eye_right.x * w), int(right_eye_right.y * h)

                right_eye_width = math.hypot(right_eye_right_x - right_eye_left_x, right_eye_right_y - right_eye_left_y)
                right_iris_to_left = math.hypot(right_iris_x - right_eye_left_x, right_iris_y - right_eye_left_y)
                right_iris_to_right = math.hypot(right_iris_x - right_eye_right_x, right_iris_y - right_eye_right_y)
                right_iris_radius = (right_iris_to_left + right_iris_to_right) / 2
                right_iris_dilation = right_iris_radius / right_eye_width

                left_iris_dilation_latest = left_iris_dilation
                right_iris_dilation_latest = right_iris_dilation

                cv2.putText(frame, f"Left Iris Dilation: {left_iris_dilation:.2f}", (30, 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 100, 0), 2)
                cv2.putText(frame, f"Right Iris Dilation: {right_iris_dilation:.2f}", (30, 90),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 100, 255), 2)

                cv2.circle(frame, (left_iris_x, left_iris_y), 3, (255, 100, 0), -1)
                cv2.circle(frame, (right_iris_x, right_iris_y), 3, (0, 100, 255), -1)

                # Gaze direction
                eye_left = face_landmarks.landmark[LEFT_EYE_LEFT]
                eye_right = face_landmarks.landmark[LEFT_EYE_RIGHT]
                iris_center = face_landmarks.landmark[LEFT_IRIS_CENTER]

                relative_iris_pos = (iris_center.x - eye_left.x) / (eye_right.x - eye_left.x)

                if relative_iris_pos < 0.35:
                    gaze_direction = "왼쪽"
                elif relative_iris_pos > 0.65:
                    gaze_direction = "오른쪽"
                else:
                    gaze_direction = "정면"

                gaze_direction_latest = gaze_direction

                cv2.putText(frame, f"Gaze: {gaze_direction}", (30, 120),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

            except IndexError:
                pass

    frame_count += 1

    if time.time() - start_time >= 10:
        blink_speed = blink_count / 10
        print(f"Blink Speed: {blink_speed:.2f} blinks/sec")

        if left_iris_dilation_latest is not None and right_iris_dilation_latest is not None:
            print(f"Left Iris Dilation: {left_iris_dilation_latest:.2f}")
            print(f"Right Iris Dilation: {right_iris_dilation_latest:.2f}")
        if gaze_direction_latest is not None:
            print(f"Gaze Direction: {gaze_direction_latest}")

        blink_count = 0
        start_time = time.time()

    cv2.imshow("Eye Tracker", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()

>>>>>>> 99b0542c81fb76e41b4840c57fc5f3122fa5d378
