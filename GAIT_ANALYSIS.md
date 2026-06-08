# 보행 분석 알고리즘 — MemoryLink

> 스마트폰 가속도계 센서 데이터를 입력으로 받아 걸음 수·거리·칼로리·보행 변동성을 실시간으로 계산하고, 이상 활동을 감지해 보호자에게 알립니다.

---

## 전체 파이프라인

```
가속도계 (X·Y·Z) → 벡터 크기 M → 걸음 감지 → 보행 주기 수집
                                                       ↓
                                             변동성(CV) 계산
                                                       ↓
                                   거리 · 칼로리 · 활동 시간 계산
                                                       ↓
                                         이상 감지 → 보호자 알림
```

---

## 1. 가속도 벡터 크기 (Acceleration Magnitude)

**파일:** `lib/features/gait_analysis/gait_analyzer.dart` · Line 36

3축 가속도를 하나의 스칼라 값으로 합산합니다.

$$M = \sqrt{x^2 + y^2 + z^2}$$

| 변수 | 단위 | 설명 |
|---|---|---|
| $x, y, z$ | m/s² | 각 축의 가속도 |
| $M$ | m/s² | 3축 합성 벡터 크기 |

```dart
final double magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
```

---

## 2. 걸음 감지 (Step Detection)

**파일:** `lib/features/gait_analysis/gait_analyzer.dart` · Line 41

아래 두 조건을 **동시에** 만족할 때만 1걸음으로 인정합니다.

$$\text{Step detected} = (M > \theta_{acc}) \;\land\; (\Delta t > \theta_{time})$$

| 상수 | 값 | 의미 |
|---|---|---|
| $\theta_{acc}$ | 1.0 m/s² | 미세 진동과 실제 걸음을 구분하는 가속도 임계값 |
| $\theta_{time}$ | 300 ms | 연속 걸음 사이 최소 시간 간격 (최고 200걸음/분까지 허용) |

```dart
static const double _stepThreshold = 1.0;   // m/s²
static const int    _minStepTimeMs  = 300;   // ms

if (magnitude > _stepThreshold &&
    now.difference(_lastStepTime!).inMilliseconds > _minStepTimeMs) {
  _stepCount++;
}
```

---

## 3. 보행 변동성 — CV (Coefficient of Variation)

**파일:** `lib/features/gait_analysis/gait_analyzer.dart` · Line 20

연속된 걸음 사이의 시간 간격 $T_1, T_2, \ldots, T_n$ 을 수집해 계산합니다.  
최소 **5걸음** 데이터가 쌓여야 계산을 시작합니다.

### 유효 보행 주기 필터

$$300\text{ ms} \;\leq\; T_i \;\leq\; 2000\text{ ms}$$

범위를 벗어난 값(노이즈·잘못된 감지)은 제외합니다.

### 평균 보행 주기

$$\mu = \frac{1}{n}\sum_{i=1}^{n} T_i$$

### 분산

$$\sigma^2 = \frac{1}{n}\sum_{i=1}^{n}(T_i - \mu)^2$$

### 표준편차

$$\sigma = \sqrt{\sigma^2}$$

### 변동성 계수

$$CV = \frac{\sigma}{\mu} \times 100\;\%$$

```dart
final double mean     = _strideTimes.reduce((a, b) => a + b) / _strideTimes.length;
final double variance = _strideTimes
    .map((x) => pow(x - mean, 2))
    .reduce((a, b) => a + b) / _strideTimes.length;
final double stdDev   = sqrt(variance);
return (stdDev / mean) * 100;
```

### 의학적 해석

| CV 범위 | 판정 | 설명 |
|---|---|---|
| < 5% | 정상 | 규칙적인 보행 리듬 |
| 5 – 10% | 경고 | 경미한 불규칙성 |
| > 10% | 고위험 | 치매·낙상 위험 전조 신호 |

---

## 4. 이동 거리

**파일:** `lib/features/gait_analysis/pedometer_manager.dart` · Line 97

$$D = \frac{N_{steps} \times L_{step}}{1000} \quad \text{(km)}$$

| 상수 | 값 | 단위 | 설명 |
|---|---|---|---|
| $L_{step}$ | 0.7 | m | 일반 성인 평균 보폭 |

```dart
_todayDistance = (_todaySteps * 0.7) / 1000.0;
```

---

## 5. 칼로리 소모량

**파일:** `lib/features/gait_analysis/pedometer_manager.dart` · Line 99

$$Cal = N_{steps} \times 0.04 \times \frac{W}{60} \times \frac{100 - A}{100} \quad \text{(kcal)}$$

| 변수 | 기본값 | 단위 | 설명 |
|---|---|---|---|
| $W$ | 60 | kg | 사용자 체중 |
| $A$ | 40 | 세 | 사용자 나이 |
| $0.04$ | — | kcal/step | 60 kg 기준 보정 계수 |

- **체중 보정** $W/60$: 60 kg 기준에서 체중 비율만큼 비례 조정
- **나이 보정** $(100-A)/100$: 고령일수록 기초대사량 감소 반영  
  (예: 68세 → 계수 0.32)

```dart
final double weight    = _userProvider.weight ?? 60.0;
final int    age       = _userProvider.age    ?? 40;
final double ageFactor = (100 - age) / 100.0;
_todayCalories = _todaySteps * 0.04 * (weight / 60.0) * ageFactor;
```

---

## 6. 활동 시간

**파일:** `lib/features/gait_analysis/gait_screen.dart` · Line 40

$$T_{activity} = \left\lfloor \frac{N_{steps}}{100} \right\rfloor \quad \text{(분)}$$

보행 속도를 **100걸음/분**으로 가정합니다.

```dart
final int activityMinutes = (pedometer.todaySteps / 100).floor();
```

---

## 7. 일일 목표 진척률

**파일:** `lib/features/gait_analysis/walking_dashboard_screen.dart` · Line 45

$$Progress = \operatorname{clamp}\!\left(\frac{N_{steps}}{10{,}000},\; 0.01,\; 1.0\right)$$

WHO 권장 일일 **10,000걸음** 기준. 최솟값 0.01은 UI 원형 게이지 표시를 위한 하한선입니다.

$$\operatorname{clamp}(x,\, a,\, b) = \begin{cases} a & x < a \\ x & a \le x \le b \\ b & x > b \end{cases}$$

```dart
final progress = (pedometer.todaySteps / 10000).clamp(0.01, 1.0);
```

### 상태 메시지

| 진척률 | 메시지 |
|---|---|
| < 30% | 조금 더 힘내볼까요! |
| 30 – 70% | 잘하고 계십니다! |
| > 70% | 목표 달성이 코앞이에요! |

---

## 8. 활동량 이상 감지 (Anomaly Detection)

**파일:** `lib/features/gait_analysis/pedometer_manager.dart` · Line 123

최근 7일 데이터 중 **3일 이상** 기록이 있을 때 실행됩니다.

### 주간 평균

$$\mu_{week} = \frac{1}{n}\sum_{i=1}^{n} S_i$$

### 이상 조건

$$Anomaly = \bigl(\mu_{week} > 1000\bigr) \;\land\; \bigl(S_{today} < 0.5 \times \mu_{week}\bigr)$$

| 임계값 | 값 | 의미 |
|---|---|---|
| 활동성 기준선 | 1,000 걸음 | 이하이면 원래부터 저활동 → 감지 제외 |
| 저하율 임계값 | 50% | 평소의 절반 미만 시 이상 판정 |
| 최소 데이터 | 3일 | 충분한 기준선 확보 |

```dart
final avgSteps = summary.map((e) => (e['steps'] as num).toDouble())
                        .reduce((a, b) => a + b) / summary.length;

if (avgSteps > 1000 && _todaySteps < (avgSteps * 0.5)) {
  await _triggerGuardianAlert(avgSteps.toInt());
}
```

---

## 9. 인지 점수 급락 감지

**파일:** `lib/core/database_helper.dart` · Line 655

이번 주 훈련 점수가 지난주 대비 **20% 이상 하락** 시 위험 사용자로 분류합니다.

$$\Delta\% = \frac{(Score_{current} - Score_{prev}) \times 100}{Score_{prev}}$$

$$Risk = \Delta\% < -20\%$$

```sql
WHERE (curr.avg_score - prev.avg_score) * 100.0
      / NULLIF(prev.avg_score, 0) < -20
```

---

## 10. 이중 과제 보행 분석 (Dual-Task)

**파일:** `lib/features/gait_analysis/precise_analysis_screen.dart` · Line 38

3분(180초) 세션 동안 40초마다 인지 미션을 제시합니다.

$$T_{task} = \lfloor remaining\_time \bmod 40 \rfloor$$

| 세션 파라미터 | 값 | 단위 |
|---|---|---|
| 총 측정 시간 | 180 | 초 |
| 과제 제시 주기 | 40 | 초 |
| 과제 표시 시간 | 10 | 초 |

**제시 과제 예시**
- 100에서 7씩 거꾸로 빼기 (산술·작업 기억)
- 동물 이름 5가지 이상 말하기 (언어 유창성)
- 어제 점심 메뉴 떠올리기 (일화 기억)

> **의학적 의의:** 정상인은 보행과 인지 과제를 동시 수행해도 CV 변화가 작습니다.  
> 치매 환자는 이중 과제 시 CV가 현저히 증가(> 15%)합니다.

---

## 전체 상수 요약

| 상수 | 값 | 단위 | 파일 |
|---|---|---|---|
| 가속도 임계값 $\theta_{acc}$ | 1.0 | m/s² | gait_analyzer.dart |
| 최소 걸음 간격 $\theta_{time}$ | 300 | ms | gait_analyzer.dart |
| 유효 보행 주기 하한 | 300 | ms | gait_analyzer.dart |
| 유효 보행 주기 상한 | 2,000 | ms | gait_analyzer.dart |
| CV 계산 최소 샘플 | 5 | 걸음 | gait_analyzer.dart |
| 평균 보폭 $L_{step}$ | 0.7 | m | pedometer_manager.dart |
| 칼로리 기준 계수 | 0.04 | kcal/step | pedometer_manager.dart |
| 기준 체중 | 60 | kg | pedometer_manager.dart |
| 이상 감지 저하율 | 50 | % | pedometer_manager.dart |
| 이상 감지 활동성 기준 | 1,000 | 걸음 | pedometer_manager.dart |
| 일일 걸음 목표 | 10,000 | 걸음 | walking_dashboard_screen.dart |
| 인지 점수 급락 임계 | -20 | % | database_helper.dart |
| 정밀 분석 세션 길이 | 180 | 초 | precise_analysis_screen.dart |
| 이중 과제 주기 | 40 | 초 | precise_analysis_screen.dart |
