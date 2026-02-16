# SMIL 기능 매트릭스 (현재 상태 + 다음 구현 대상)

> 기준일: 2026-02-16
> 적용 범위: `Examples/SVGSwiftUIDemo/Resources/W3C/animation/*.svg` + 데모 UI 등록 샘플

## 1) 기능 카테고리

| 기능 | 현재 상태 | 이유 | 대표 샘플 | 테스트 |
|---|---|---|---|---|
| `animate` | 파서 수집 + 타이밍/속성 스켈레톤 해석 | `SVGSMILAnimation`에 `timing`, `attributeName`, `from/to/by`, `values`, `calcMode` 일부 저장 | `animation-smil-drift-lines`, `animation-smil-wave-cascade`, `animation-smil-color-lattice` | `SVGParserTests`로 `dur/begin/repeatCount` 해석 검증 |
| `animateTransform` | 파서 + 렌더 기본 보간 지원 | `SVGSMILAnimation`에 `type`, `from/to/by`, `values`를 기준으로 transform 보간 적용 | `animation-smil-radar-spin`, `animation-smil-orbital`, `animation-smil-pulse-sunburst` | `SVGParserTests` + `SVGSMILEngineTests` |
| `set` | 파서 수집 + 타이밍/속성 스켈레톤 해석 | `SVGSMILAnimation`에 `attributeName`, `to`, `dur`, `begin` 저장 | `animation-smil-drift-lines` (속성 변경), `animation-smil-breath-grid` | `SVGParserTests` 신규 케이스 추가 |
| `animateMotion` | 파서+기본 렌더 보간 지원 | `from/to` 좌표 이동과 `path` 기본 이동/회전 처리 지원(`auto`, `auto-reverse`, `fixed`) | `animation-smil-orbit-lumen`, `animation-smil-wave-shimmer` (샘플 단계 확충 예정) | `SVGSMILEngineTests` |
| SMIL 시간 모델 (`dur`, `begin`, `repeatCount`) | 부분 지원 | 기본 dur/begin/repeat는 동작, keyTimes/keySplines/이벤트 begin 미지원 | 전 샘플 | M1-6+에서 고도화 |
| 보간 값 (`values` / `keyTimes` / `keySplines`) | 부분 지원 | `from/to/by/values` 기본 보간은 지원, keyTimes/keySplines는 미지원 | 전 샘플 | M1-6에서 고도화 |
| 경로 기반 이동 (`path`, `keyPoints`, `rotate`) | 부분 지원 | `path` + `rotate`(auto/auto-reverse/fixed) 처리 시작. `keyPoints` 미지원 | 전 샘플 | M1-7에서 keyPoints/정밀도 보강 |

## 2) 비지원 상태 라벨 규칙

- 현재 구현에서 `animate`/`set`/`animateTransform`/`animateMotion`는 파싱 단계에서 `unsupportedFeatures` 대신 `SVGDocument.animations`로 수집됩니다.
- `unsupportedFeatures`는 여전히 미지원 SMIL(`animateColor`, `animateOpacity` 등) 추적용으로 남아 있습니다.
- SMIL 샘플은 향후 `expected: unsupported` 또는 `mixed` 정책으로 정량 관리되며, 파서 수집/렌더 반영 단계는 분리해 추적해야 합니다.

## 3) 데모 샘플별 SMIL 사용량(요약)

| 파일명 | 주요 태그 | 비고 |
|---|---|---|
| `animation-smil-drift-lines.svg` | `animate` | cx 보간 예시 |
| `animation-smil-pulse-sunburst.svg` | `animate` | r, opacity 계열 값 변화 |
| `animation-smil-radar-spin.svg` | `animateTransform` | rotate |
| `animation-smil-breath-grid.svg` | `animate`, `animateTransform` | transform + 속성 애니메이션 혼합 |
| `animation-smil-color-lattice.svg` | `animateTransform` | 그룹 단위 회전 |
| `animation-smil-spin-petal.svg` | `animate`, `animateTransform` | 반지름+회전 혼합 |
| `animation-smil-orbital.svg` | `animateTransform` | 회전/반환 구조 |
| `animation-smil-orbit-lumen.svg` | `animateTransform` | 노드 중심 스케일/회전 느낌 |
| `animation-smil-wave-cascade.svg` | `animate` | begin 오프셋 다중 시작 |
| `animation-smil-wave-shimmer.svg` | `animate`, `animateTransform` | 파형+선형 이동 |
| `animation-smil-orbit-multi-ring.svg` | `animateTransform` | 다중 ring 동기화 |
| 추가 예정 샘플 | `animate*` | 현재 미존재 샘플군 확인 후 단계별 추가 예정 |

## 4) 우선순위 제안 (로드맵 정합)

- 1차 (M1): `animate`, `animateTransform`, 시간/반복 모델(`dur`, `begin`, `repeatCount`) 구현
- 2차 (M2): `values`, `keyTimes`, `keySplines`, 색상/숫자형 보간기
- 3차 (M3): `animateMotion` + 경로 보간
- 4차 (M4): `set`, advanced timing/offset 조정 (`indefinite`, begin/end 링크)
- 운영 단계: `unsupportedFeatures` 정합 + 문서/CI 반영

## 5) 단계별 완료 조건 (현재 계획)

- M1에서 정량화되는 샘플 최소 수: 6개 이상
- M2에서 `values`/`keyTimes` 기반 샘플: 4개 이상
- M3에서 `animateMotion` 샘플: 별도 수집 후 2개 이상
- M4에서 `set` 샘플 최소 1개 이상 확보(미설치 샘플은 외부 수집 필요)
