"""
MemoryLink 인지 발화 분석 TFLite 모델 학습 스크립트
=====================================================

사용법:
  pip install tensorflow numpy scikit-learn
  python scripts/train_cognitive_model.py

출력:
  assets/models/cognitive_classifier.tflite  (앱에 번들링)

입력 특성 (10개):
  [0] TTR normalized           어휘 다양성 (0~1)
  [1] WPM normalized           발화 속도 / 160
  [2] 총 단어 수 normalized    / 50
  [3] 문장 완결성              종결 어미 비율
  [4] 반복 어구 비율           높을수록 나쁨
  [5] 위험 키워드 밀도         "기억이 안" 등
  [6] 충전어 비율              어, 음, 그 등
  [7] 평균 문장 길이 / 10
  [8] 어휘 풍부도              3글자 이상 고유어 비율
  [9] 발화 지속성              실제 발화 시간 / 90초

출력 (2개):
  [0] cognitive_score (0~1)   높을수록 인지 건강 상태 양호
  [1] risk_score (0~1)        높을수록 위험
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split

# ──────────────────────────────────────────────────────────────────────────
# 1. 학습 데이터 정의
#    실제 사용 시 이 섹션을 실제 수집 데이터로 교체하세요.
#    각 행: [ttr, wpm/160, words/50, completion, repeat, risk, filler,
#            avg_sentence/10, rich_ratio, duration/90]
# ──────────────────────────────────────────────────────────────────────────

# 양호 샘플 (cognitive_score≈0.85, risk≈0.05)
HEALTHY_SAMPLES = [
    [0.72, 0.75, 0.90, 0.80, 0.02, 0.00, 0.05, 0.60, 0.65, 0.85],
    [0.68, 0.70, 0.85, 0.75, 0.03, 0.00, 0.04, 0.55, 0.60, 0.80],
    [0.75, 0.80, 0.95, 0.85, 0.01, 0.00, 0.03, 0.65, 0.70, 0.90],
    [0.65, 0.68, 0.80, 0.70, 0.04, 0.00, 0.06, 0.50, 0.58, 0.75],
    [0.80, 0.85, 1.00, 0.90, 0.01, 0.00, 0.02, 0.70, 0.75, 0.95],
    [0.70, 0.72, 0.88, 0.78, 0.02, 0.00, 0.05, 0.58, 0.62, 0.82],
    [0.73, 0.76, 0.92, 0.82, 0.02, 0.00, 0.04, 0.62, 0.67, 0.88],
    [0.67, 0.71, 0.84, 0.74, 0.03, 0.00, 0.05, 0.53, 0.59, 0.78],
    [0.78, 0.82, 0.96, 0.88, 0.01, 0.00, 0.03, 0.68, 0.72, 0.92],
    [0.71, 0.74, 0.89, 0.79, 0.02, 0.00, 0.04, 0.59, 0.64, 0.84],
    [0.74, 0.77, 0.93, 0.83, 0.02, 0.00, 0.04, 0.63, 0.68, 0.89],
    [0.66, 0.69, 0.82, 0.72, 0.03, 0.00, 0.06, 0.51, 0.57, 0.76],
    [0.79, 0.83, 0.97, 0.89, 0.01, 0.00, 0.02, 0.69, 0.73, 0.93],
    [0.69, 0.73, 0.87, 0.77, 0.02, 0.00, 0.05, 0.57, 0.61, 0.81],
    [0.76, 0.79, 0.94, 0.84, 0.01, 0.00, 0.03, 0.64, 0.69, 0.90],
]

# 보통 샘플 (cognitive_score≈0.55, risk≈0.20)
MODERATE_SAMPLES = [
    [0.50, 0.55, 0.60, 0.50, 0.10, 0.17, 0.12, 0.40, 0.42, 0.55],
    [0.45, 0.50, 0.55, 0.45, 0.12, 0.17, 0.14, 0.35, 0.38, 0.50],
    [0.55, 0.60, 0.65, 0.55, 0.08, 0.00, 0.10, 0.45, 0.46, 0.60],
    [0.42, 0.48, 0.52, 0.42, 0.14, 0.17, 0.16, 0.32, 0.35, 0.47],
    [0.58, 0.62, 0.68, 0.58, 0.07, 0.00, 0.09, 0.48, 0.50, 0.63],
    [0.48, 0.53, 0.58, 0.48, 0.11, 0.17, 0.13, 0.38, 0.40, 0.53],
    [0.52, 0.57, 0.62, 0.52, 0.09, 0.00, 0.11, 0.42, 0.44, 0.57],
    [0.44, 0.49, 0.54, 0.44, 0.13, 0.17, 0.15, 0.34, 0.37, 0.49],
    [0.56, 0.61, 0.66, 0.56, 0.08, 0.00, 0.10, 0.46, 0.48, 0.61],
    [0.47, 0.52, 0.57, 0.47, 0.12, 0.17, 0.13, 0.37, 0.39, 0.52],
    [0.51, 0.56, 0.61, 0.51, 0.10, 0.00, 0.11, 0.41, 0.43, 0.56],
    [0.43, 0.48, 0.53, 0.43, 0.13, 0.17, 0.15, 0.33, 0.36, 0.48],
    [0.57, 0.62, 0.67, 0.57, 0.07, 0.00, 0.09, 0.47, 0.49, 0.62],
    [0.46, 0.51, 0.56, 0.46, 0.11, 0.17, 0.13, 0.36, 0.39, 0.51],
    [0.54, 0.59, 0.64, 0.54, 0.09, 0.00, 0.10, 0.44, 0.46, 0.59],
]

# 주의 샘플 (cognitive_score≈0.25, risk≈0.50)
CONCERN_SAMPLES = [
    [0.30, 0.35, 0.30, 0.20, 0.25, 0.50, 0.25, 0.20, 0.22, 0.30],
    [0.25, 0.30, 0.25, 0.15, 0.28, 0.50, 0.28, 0.15, 0.18, 0.25],
    [0.35, 0.40, 0.35, 0.25, 0.22, 0.33, 0.22, 0.25, 0.26, 0.35],
    [0.22, 0.27, 0.22, 0.12, 0.30, 0.50, 0.30, 0.12, 0.15, 0.22],
    [0.38, 0.43, 0.38, 0.28, 0.20, 0.33, 0.20, 0.28, 0.29, 0.38],
    [0.28, 0.33, 0.28, 0.18, 0.26, 0.50, 0.26, 0.18, 0.20, 0.28],
    [0.32, 0.37, 0.32, 0.22, 0.24, 0.33, 0.24, 0.22, 0.24, 0.32],
    [0.23, 0.28, 0.23, 0.13, 0.29, 0.50, 0.29, 0.13, 0.16, 0.23],
    [0.36, 0.41, 0.36, 0.26, 0.21, 0.33, 0.21, 0.26, 0.27, 0.36],
    [0.27, 0.32, 0.27, 0.17, 0.27, 0.50, 0.27, 0.17, 0.19, 0.27],
    [0.31, 0.36, 0.31, 0.21, 0.25, 0.33, 0.25, 0.21, 0.23, 0.31],
    [0.24, 0.29, 0.24, 0.14, 0.29, 0.50, 0.29, 0.14, 0.17, 0.24],
    [0.37, 0.42, 0.37, 0.27, 0.21, 0.33, 0.21, 0.27, 0.28, 0.37],
    [0.26, 0.31, 0.26, 0.16, 0.27, 0.50, 0.27, 0.16, 0.18, 0.26],
    [0.33, 0.38, 0.33, 0.23, 0.23, 0.33, 0.23, 0.23, 0.25, 0.33],
]

# 레이블 생성 [cognitive_score, risk_score]
def make_labels(samples, cog_score, risk_score, noise=0.05):
    labels = []
    for _ in samples:
        c = np.clip(cog_score + np.random.uniform(-noise, noise), 0, 1)
        r = np.clip(risk_score + np.random.uniform(-noise, noise), 0, 1)
        labels.append([c, r])
    return labels

X = np.array(HEALTHY_SAMPLES + MODERATE_SAMPLES + CONCERN_SAMPLES, dtype=np.float32)
y = np.array(
    make_labels(HEALTHY_SAMPLES,  0.85, 0.05) +
    make_labels(MODERATE_SAMPLES, 0.55, 0.20) +
    make_labels(CONCERN_SAMPLES,  0.25, 0.50),
    dtype=np.float32
)

print(f"학습 데이터: {len(X)}개 샘플, 입력 특성 {X.shape[1]}개")

# ──────────────────────────────────────────────────────────────────────────
# 2. 모델 정의 및 학습
# ──────────────────────────────────────────────────────────────────────────

X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)

model = keras.Sequential([
    keras.layers.Input(shape=(10,)),
    keras.layers.Dense(32, activation='relu'),
    keras.layers.Dropout(0.2),
    keras.layers.Dense(16, activation='relu'),
    keras.layers.Dense(2, activation='sigmoid'),
], name='cognitive_classifier')

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss='mse',
    metrics=['mae'],
)

model.summary()

history = model.fit(
    X_train, y_train,
    validation_data=(X_val, y_val),
    epochs=200,
    batch_size=8,
    verbose=1,
    callbacks=[
        keras.callbacks.EarlyStopping(patience=20, restore_best_weights=True),
        keras.callbacks.ReduceLROnPlateau(patience=10, factor=0.5),
    ],
)

val_loss = min(history.history['val_loss'])
print(f"\n최적 검증 손실: {val_loss:.4f}")

# ──────────────────────────────────────────────────────────────────────────
# 3. TFLite 변환 및 저장
# ──────────────────────────────────────────────────────────────────────────

output_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'models')
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, 'cognitive_classifier.tflite')

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # float16 양자화
tflite_model = converter.convert()

with open(output_path, 'wb') as f:
    f.write(tflite_model)

size_kb = len(tflite_model) / 1024
print(f"\n[완료] TFLite 모델 저장: {output_path}")
print(f"   모델 크기: {size_kb:.1f} KB")

# ──────────────────────────────────────────────────────────────────────────
# 4. 추론 검증 (Flutter와 동일한 입력/출력 확인)
# ──────────────────────────────────────────────────────────────────────────

interp = tf.lite.Interpreter(model_path=output_path)
interp.allocate_tensors()
inp = interp.get_input_details()
out = interp.get_output_details()

print(f"\n입력 shape: {inp[0]['shape']}  dtype: {inp[0]['dtype']}")
print(f"출력 shape: {out[0]['shape']}  dtype: {out[0]['dtype']}")

test_cases = [
    ("양호 샘플", np.array([[0.72, 0.75, 0.90, 0.80, 0.02, 0.00, 0.05, 0.60, 0.65, 0.85]], dtype=np.float32)),
    ("보통 샘플", np.array([[0.50, 0.55, 0.60, 0.50, 0.10, 0.17, 0.12, 0.40, 0.42, 0.55]], dtype=np.float32)),
    ("주의 샘플", np.array([[0.30, 0.35, 0.30, 0.20, 0.25, 0.50, 0.25, 0.20, 0.22, 0.30]], dtype=np.float32)),
]

print("\n── 추론 검증 ──")
for label, test_input in test_cases:
    interp.set_tensor(inp[0]['index'], test_input)
    interp.invoke()
    result = interp.get_tensor(out[0]['index'])[0]
    print(f"{label}: cognitive={result[0]*100:.1f}점  risk={result[1]:.2f}")

print("\n다음 단계: Flutter 앱을 다시 빌드하면 TFLite 모델이 자동으로 로드됩니다.")
