# WebKit LayoutTests 기반 검증 계획

## 목표
- WebKit `LayoutTests/svg`의 시그널을 활용해 현재 구현이 SVG 스펙 레이어와 얼마나 일치하는지 확인한다.
- 단일 테스트 러너를 추가하여 WebKit 기준과의 공백을 정량적으로 추적한다.

## 적용 범위(1차)
- `LayoutTests/svg` 전체를 즉시 동기화하지 않고, 구현 범위에 맞는 후보를 선별한다.
- 소스 기준: https://github.com/WebKit/WebKit/tree/main/LayoutTests/svg
- 1차 대상:
  - `path` 기본 동작
  - `rect/circle/ellipse/polygon/polyline` 기본 변환
  - `fill/stroke` 기본 속성
  - `clipPath`/`mask`/`filter` 태그 존재 케이스의 파서 안정성

## 제안 아키텍처
- `Scripts/webkit/` 하위에 소스 목록 기반 동기화 스크립트를 둔다.
- 고정된 WebKit 테스트 ID 리스트(원본 경로 + 기대 동작)를 로컬 매니페스트로 관리한다.
- 변환기는 WebKit 기대값을 `SVGSwiftUI` 테스트 포맷으로 정규화한다.
  - 파싱 전용: parse 성공/실패 기대
  - 렌더 전용: baseline 비주얼 비교 가능 시 기존 `UITest` 흐름으로 확장
- 결과는 `A10-1` 완료 조건에 맞춰 별도 커버리지 리포트로 축적한다.

## 단계별 실행
1. WebKit 대상 목록 선정
- `WebKit/LayoutTests/svg`에서 실질적으로 동일한 기능군 20~40건 선별
- 각 케이스에 대해 기대 시나리오(`pass`, `fail`, `unsupported`)를 명시
- unsupported 케이스는 구현 예정이지만 파서 안정성 확인이 필요한 항목을 우선 수집

2. 정합성 규칙 고정
- `Tests/SVGSwiftUITests/WebKit/webkit-manifest.json`을 단일 소스 오브 트루스로 사용한다.
- `source`는 항상 `LayoutTests/svg/W3C-SVG-1.1/...` 형태를 유지한다.
- `svg`는 매니페스트와 동일한 baseline 리소스명을 사용한다(필요 시 `fixtures/` 접두사 정규화).
- 매니페스트 갱신 후 `scripts/webkit/fetch-layout-tests.sh`로 `fixtures` 동기화하고, 매니페스트 미등재 파일은 제거해 정합성을 유지한다.

3. 변환기 구현
- 매니페스트 기반으로 `Tests/SVGSwiftUITests/WebKitGeneratedTests.swift`를 생성
- 기존 `W3CGeneratedTests.swift`와 동일한 생성 규칙을 재사용

4. 실행 통합
- `swift test --filter testWebKitGeneratedSuite --no-parallel` 형태로 분리 실행
- CI는 W3C와 독립 잡으로 구성(실행 시간 과부하 분리)

5. 품질 게이트
- `unsupported`는 `unsupported`로 분리 집계해 신호만 추적
- 구현이 지원 대상으로 전환되면 기대값도 `pass`로 상향
- CI strict 모드는 최소 `missing/reference`, `invalid id`, `invalid mode/expected`를 fail 조건으로 처리

## 체크리스트
- [x] `Scripts/webkit/fetch-layout-tests.sh` 초안 작성
- [x] `Tests/SVGSwiftUITests/WebKit/webkit-manifest.json` 생성
- [x] `Scripts/webkit/generate-webkit-tests.sh` 추가
- [x] `Tests/SVGSwiftUITests/WebKitGeneratedTests.swift` 생성
- [x] `Scripts/webkit/webkit-coverage.sh` 추가
- [x] `Tests/SVGSwiftUITests/WebKit/fixtures/*.svg` WebKit 1차 후보군 수동 동기화
- [x] CI 워크플로우에 WebKit conformance 실행 단계 추가
- [x] 지원 범위 외 항목의 `unsupported` 후보 20~40건으로 확장
- [x] `A10-3` manifest 기준(기대값/ID/참조 소스) 정합성 규칙 문서화 및 리뷰 체크리스트 반영
