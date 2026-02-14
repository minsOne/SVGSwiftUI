# W3C SVG Conformance Test Plan (Future)

## 목적
- SVG 구현이 표준에 얼마나 부합하는지 정량적으로 검증한다.
- 지원 범위 내 회귀를 CI에서 자동 차단한다.

## 참고 구현
- `exyte/SVGView`의 W3C 테스트/커버리지 접근을 참조:
  - `w3c-coverage.sh`
  - `script-test-cases.sh`
  - `w3c-coverage.md`

## 적용 범위(1차)
- SVG 1.1 + Tiny 1.2 전체를 한 번에 커버하지 않고, 현재 지원 요소 중심으로 시작:
  - paths
  - shapes
  - coords
  - styling(지원 속성 범위 내)
- 미지원 항목(예: animation, filter, text 등)은 `unsupported`로 분리 집계한다.

## 단계별 도입
1. Fixture import
- 디렉터리 구조:
  - `Tests/W3C/fixtures/1.1F2/svg`
  - `Tests/W3C/fixtures/1.1F2/ref`
  - `Tests/W3C/fixtures/1.2T/svg`
  - `Tests/W3C/fixtures/1.2T/ref`
- 최초에는 소규모 subset(카테고리당 5~20개)으로 시작.

2. Manifest 기반 테스트 정의
- `Tests/W3C/w3c-manifest.json`에 테스트 메타데이터 저장:
  - id
  - suite(1.1F2/1.2T)
  - category
  - mode(parse/render)
  - expected(pass/fail/unsupported)

3. 테스트 코드 자동 생성
- 스크립트: `Scripts/generate-w3c-tests.sh`
- 입력: manifest + fixture 목록
- 출력: `Tests/SVGSwiftUITests/W3CGeneratedTests.swift`

4. 비교 전략
- parse 모드:
  - 에러/성공 기대값 비교
  - AST 핵심 필드 비교(노드 수, path command, 속성)
- render 모드:
  - baseline 이미지와 비교(허용 오차 포함)
  - Demo UITest baseline 체계와 동일 정책 재사용

5. coverage 리포트
- 스크립트: `Scripts/w3c-coverage.sh`
- 산출물:
  - `docs/W3C_COVERAGE.md`
  - 카테고리별 pass/fail/unsupported 비율

6. CI 통합
- 잡:
  - `swift test` 기본 테스트
  - W3C parse subset 테스트
  - W3C render subset 테스트(고정 시뮬레이터 환경)
- 실패 시:
  - diff 이미지/로그 아티팩트 업로드

## 중복 작업 방지 규칙
1. 신규 W3C 케이스 추가 시 manifest를 단일 source of truth로 사용
2. baseline 갱신은 PR에서 이유를 `WORK_LOG.md`에 기록
3. unsupported -> supported 전환 시 해당 테스트의 expected를 명시적으로 변경

## 초기 완료 기준
1. 카테고리별 최소 fixture 세트 구축(paths/shapes/coords/styling)
2. 자동 생성된 W3C 테스트가 CI에서 실행됨
3. `docs/W3C_COVERAGE.md` 자동 갱신 파이프라인 구축
4. 지원 범위 회귀 시 CI fail 확인
