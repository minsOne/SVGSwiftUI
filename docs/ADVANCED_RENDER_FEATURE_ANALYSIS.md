# 고급 렌더 기능 후보 분석 (S2-1)

## 분석 목적
- 렌더 경로에 `clipPath`, `mask`, `filter`(및 masking 계열)을 도입하기 전에
  - 지원 범위를 축소한 우선순위를 정한다.
  - 1차 구현 범위를 결정한다.
  - W3C conformance 테스트 후보를 정한다.
- 목표는 안정적인 렌더링 기반을 깨지 않는 범위에서 기능 확장을 진행하는 것이다.

## 현재 제약
- 렌더러는 `Canvas`에서 `Path` 기반 fill/stroke를 중심으로 동작한다.
- 현재 파서는 알 수 없는 태그를 무시하고, 지원 노드만 트리로 유지한다.
- 현재 스타일 해석은 기본 속성/inline/CSS subset에 국한되어 있다.
- 현재 `node <-> style` 오버라이드는 구현되어 있으나, 고급 그래픽 마스킹/필터 체인은 미지원이다.

## 후보 분석

### clipPath
- 기대 효과:
  - `clip-path` 속성의 제한 부분 집합 지원으로 실제 SVG 렌더에서 가시성 제어 가능.
- 필수 선행:
  - `clipPath` 노드/참조 ID 보존(확장 필요)
  - 참조 대상 경로 집합 생성(`path`, `rect`, `circle`, `ellipse`, `polygon`, `polyline`)
  - 렌더 단계에서 `GraphicsContext` 클리핑 API를 통한 경로 적용
- 난이도:
  - 중간 (`중간`).
- W3C 테스트 후보:
  - 신규 카테고리 `clipping`에서 pass 테스트를 3~8개 정도 추가.
  - 초기는 `url(#id)` 참조 + 간단 경로 집합 1~2건으로 시작.
- 우선순위:
  - `S2-2`에서 1차 타깃으로 지정.

### mask
- 기대 효과:
- alpha mask를 지원하면 `clipPath`보다 표현력이 넓어짐.
- 난이도:
  - 높음 (뷰포트 단위 임시 레스터링 및 혼합 모드 필요).
- 현재 엔진 제약:
- `Canvas` 단계만으로는 정확한 SVG mask 동작을 구현하기 어렵고, 별도 오프스크린 렌더 또는 CoreImage 의존성이 필요.
- 우선순위:
  - `S2-2` 보류.
  - `S3`에서 비용/성능 검토 후 착수.

### filter
- 기대 효과:
- `filter` 체인 도입 시 blur/offset/opacify 같은 표현력 향상.
- 난이도:
  - 매우 높음 (필터 primitive 파서 + 레스터 합성 + 성능 영향 큼).
- W3C 이행 난이도:
- 표준 내 `fe*` 집합이 넓어 부분 지원 정의가 필수.
- 우선순위:
  - `S2` 범위 제외.
  - 별도 v3 성능/표현 트랙으로 이관 검토.

### masking (총칭)
- `mask`와 `clipPath`를 통합 용어로 관리.
- 정책:
  - 1차는 `clipPath`만 `masking`의 실질 대응으로 보고,
  - `mask/filter`는 미지원 항목으로 분류해 coverage에 고정.

## S2-1 결정안
- 결정:
  - `clipPath`를 S2-2 최소 구현 범위로 채택.
  - `mask`, `filter`, 완전한 masking(투명도/채널 기반)은 S2 외부로 분리.
- 구현 전제:
  - parser가 일단 `clipPath`, `mask`, `filter` 태그를 `unsupportedTag`로 정리해도 실패 없이 처리.
  - 향후 `S2-2`에서 clipPath 대상 노드/속성 추출 테스트를 먼저 작성.
- 다음 전제 검토 항목:
  - 기존 W3C fixture에 `clipping` 카테고리 항목 1~2개 추가 후 strict 모드가 `unsupported` 집계도 허용되는지 검증.
