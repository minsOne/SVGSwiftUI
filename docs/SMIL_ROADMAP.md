# SMIL 고급 기능 로드맵 (체크리스트)

최종 목표: SwiftUI `Path` 렌더러 기반 파이프라인에서 **SMIL 애니메이션을 점진적으로 지원**하고,  
W3C/WebKit 수준으로 정합성을 높이되 기본 범위를 명확히 분리한다.

현재 기준 점검:
- 파서는 기본 그래픽 요소 + SMIL 핵심 태그(`animate`, `set`, `animateTransform`, `animateMotion`)의 프레임을 수집해 `SVGDocument.animations`에 보관.
- 미지원 항목(`animateColor` 등)은 `unsupportedFeatures`로 계속 추적.
- `SVGView`는 Timeline 기반 업데이트 경로에서 `animateMotion`/`animateTransform`/`animate` 값을 반영하도록 동작.
- M1-8 단계: W3C/웹 브라우저 비교 시나리오 연동 마무리(`browser-oracle` manifest 정합 + SMIL Baseline 검증).

---

## 1) 준비 단계

- [x] `SMIL` 우선순위와 범위 재정의
  - 목표: v1에서 지원할 최소 기능, vNext에서 확장할 기능을 분리.
  - 산출물: `docs/SMIL_FEATURE_MATRIX.md` (요건별 상태표)
  - 완료 기준:
    - 최소 기능 70% 이상을 통합 테스트로 검증 가능.
    - 고급 기능은 별도 플래그로 분기.

- [x] 기존 문서 및 샘플 정합성 점검
  - `docs/W3C_COVERAGE.md`, `docs/WEBKIT_COVERAGE.md`, 데모 타임라인 샘플 재확인.
  - 완료 기준: 현재 미지원 SMIL 요소와 샘플을 체크리스트로 정리.

- [x] 공개 API 영향도 점검
  - `SVGParser`, `SVGDocument`, 렌더 관련 타입 변경 영향 분석.
  - 완료 기준: 기존 v1 API를 깨지 않는 방향으로 설계한 패치 노트 초안 작성.

---

## 2) 핵심 데이터 모델

- [x] SMIL 공통 모델 추가
  - `Sources/SVGSwiftUI/Model/`에 `SVGAnimation.swift` 추가(내부 타입 우선)
  - 포함 요소:
    - `SVGSMILAnimation`, `SVGSMILAnimationValue`, `SVGSMILAnimationTiming`, `SVGSMILAnimationValueInterpolation`
    - 반복/중단/채우기 정책 열거형
  - 완료 기준:
    - `Sendable`, Equatable 성질 유지.
    - 단일 노드의 다중 애니메이션 묶음 표현 가능.

- [ ] 노드에 애니메이션 참조 연결
  - `SVGBaseNode` 또는 노드 wrapper에 `animationReferences`/`animations` 필드 추가.
  - `id/targetAttribute` 기반 바인딩 구조 설계.
  - 완료 기준:
    - 파서 결과에서 동일 `id` 대상의 애니메이션을 노드와 매칭할 수 있어야 함.

---

## 3) 파서 단계

- [x] 프레임 인식 확장
  - `SVGXMLDocumentParser`의 `FrameKind`/`frameKind(for:)`에 SMIL 태그 인식 추가.
  - `ignored elements`가 아니라 노드로 유지할 수 있도록 파서 트래킹 경로 설계.
  - 완료 기준:
    - `animate`, `set`, `animateTransform` 기본 시작/종료 이벤트 파싱 가능.

- [x] `animate` 파서 구현
  - 속성: `attributeName`, `from`, `to`, `by`, `dur`, `repeatCount`, `repeatDur`, `values`, `keyTimes`, `fill`, `begin`, `end`, `calcMode`.
  - 기본 타입 추론: `number`, `length`, `color`, `path`, `transform` 대응.
  - 완료 기준:
    - 유효한 attribute 조합에 대한 유닛 테스트 10개 이상.
    - 불완전/비표준 조합은 `unsupportedFeatures` 집계.

- [x] `set` / `animateColor` / `animateOpacity` 대응
  - `set`의 정적 값 전환을 공통 `animate` 엔진에서 처리.
  - color/opacity 특화 타입 디코더 추가.
  - 완료 기준:
    - 색상/투명도만 쓰는 샘플 3종 이상 통과.

- [x] `animateTransform` 파서 구현
- [x] `animateMotion` 기초 구현
  - path 기반 이동(`path`, `keyPoints`, `rotate`) 최소 스펙으로 지원.
  - 완료 기준:
    - 단일 path 기반 이동 샘플 2종 통과.

- [x] 타이밍 규칙 정리
  - 완료 상태:
    - `dur`, `begin`, `end`, `repeatCount`, `repeatDur`, `fill`의 1차 해석 완료.
    - `indefinite` repeat는 `repeatCount` enum으로 보존.
    - 현재 버전은 시간 토큰 기반 파싱이며 `indefinite`/이벤트형 토큰은 지원 범위에서 제외.
  - `begin="xsmil"`류 확장 규칙은 초기 단계에서 제외 가능 범위로 명시.
  - `indefinite/repeatCount="indefinite"` 처리.
  - 완료 기준:
    - 내부 문서화(어떤 규칙을 지원/미지원인지) 완료.

---

## 4) 애니메이션 엔진

- [ ] 샘플러(시간 계산기) 구현
  - 공통 함수 `sample(value: timing: at:) -> SVGAnimationValue`
  - `duration`, `begin`, `repeat`, `keyTimes`, `keySplines` 처리.
  - 완료 기준:
    - 순수 단위 테스트에서 수치 오차 범위 내 일치.

- [x] 값 보간기 구현 (M1-5)
  - scalar, length, color, point, transform matrix 보간.
  - 현재 범위는 `from/to/by/values`의 주요 수치형/색상/transform 기본 케이스.
  - `keyTimes`, `keySplines`, 고급 충돌 해석은 다음 단계로 이관.
  - 완료 기준:
    - 각 타입별 보간 유닛 테스트.

- [ ] 애니메이션 해결값 병합기
  - 노드 스타일/속성에 `base/style/animation` 우선순위 적용.
  - 동일 속성 다중 애니메이션 conflict 해결 정책 고정.
  - 완료 기준:
    - 우선순위 테스트 케이스 10개 이상.

- [x] 렌더 타임라인 연동
- `SVGView`에 SwiftUI 타임 소스로부터 현재 시간을 주입하고, 매 프레임 `drawNodes`를 재해석.
  - 기존 static 캐시가 깨지지 않도록 시간 의존 경로만 분리.
  - 완료 기준:
    - 애니메이션이 있는 샘플에서 화면이 연속 갱신되는지 UI/UITest로 확인.

---

## 5) 렌더/성능 안정화

- [ ] `TimelineView` 기반 갱신 경로 정리
  - animation 대상만 업데이트하고 non-animated 경로는 기존 static cache 유지.
  - 완료 기준:
    - static 렌더 성능 baseline 대비 회귀 없음(기존 벤치마크 기준).

- [ ] offscreen/필터 통합
  - 필터 적용 경로에서 animated fill/stroke/transform가 반영되도록 수정.
  - 완료 기준:
    - 필터+애니메이션 샘플 1종 통합 테스트.

- [ ] 에러·미지원 처리
  - 미지원 SMIL 유형은 `SVGDocument.unsupportedFeatures`에 남기되 렌더는 중단하지 않음.
  - 완료 기준:
    - 실패 모드 테스트에서 앱 크래시 없이 fallback 동작.

---

## 6) 테스트 & 검증

- [ ] 파서 테스트
  - `Tests/SVGSwiftUITests`에 SMIL 전용 UnitTest 그룹 추가.
  - 완료 기준:
    - 파서 레이어 테스트 100% 통과 + 신규 커버리지 증가.

- [x] UI/시각 테스트
  - `Examples/SVGSwiftUIDemo`에 "Animation" 탭으로 SMIL 샘플 분리.
  - 각 샘플별:
    - 렌더 시작/중간/끝 상태 캡처
    - 변환/색상/위치 keypoint 검증
  - 완료 기준:
    - 기존 `SVGDemo` UITest 구조에 새 시나리오 분리 완료.

- [x] W3C/ WebKit 근접 검증
  - W3C 애니메이션 관련 subset fixture 기반 smoke test로 시작.
  - 이후 `WEBKIT_LAYOUT_TESTS_PLAN.md` 연동 단계로 승격.
  - 완료 기준:
    - 지원 범위별 pass/fail/unsupported 매트릭스 산출.

---

## 7) 배포 전 정리

- [ ] 문서화
  - 지원/미지원 SMIL 목록, 사용 제한, 샘플별 예상 동작을 문서화.
  - 완료 기준:
    - README와 데모 도움말에 반영.

- [ ] API/보안/패키징 체크
  - `public` 과잉 노출 최소화.
  - release artifact에서 SMIL 영향 테스트 수행.
  - 완료 기준:
    - CI 통과 + demo 앱 실행, UITest, 릴리스 스크립트 회귀 없음.

---

## 실행 규칙

- 각 단계를 끝낼 때마다 `docs/WORK_LOG.md`에 체크리스트 결과만 기록.
- 각 Step 완료 전/후:
  - `swift test` 실행
  - demo target 테스트 1회
  - `git status`, commit message with step ID
- 다음 Step 시작 시:
  - 이전 Step의 미지원 항목은 `unsupportedFeatures` 리포트와 동기화.
- 위험 항목은 별도 이슈로 분리:
  - `animateMotion path + rotate`
  - keyTimes/spline 보간
  - 다중 `begin` 링크 동작
