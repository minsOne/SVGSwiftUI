# SVGSwiftUI Task Board

Last Updated: 2026-02-16 (A14-3 done)

## Status Legend
- `todo`: not started
- `in_progress`: currently active
- `done`: completed and verified
- `blocked`: waiting on dependency/decision

## Workflow Rule (mandatory)
- 시작: `in_progress`로 전환 후 작업 항목 및 범위 확정
- 진행: 단위/통합 테스트와 conformance 커버리지 실행
- 정리: 변경 근거를 `WORK_LOG.md`에 세션 단위로 기록
- 완료: `done` 변경 전에 커밋 및 푸시를 완료
- 유지: 다음 작업 시작 전 `WORK_CONTINUATION` 상태와 `Last Updated`를 동기화

## v1 Milestones
| ID | Phase | Task | Status | Notes |
|---|---|---|---|---|
| P0-1 | P0 | Swift Package bootstrap | done | `swift package init --type library` 완료 |
| P0-2 | P0 | iOS 15+ package platform 설정 | done | `Package.swift` 플랫폼 지정 완료 |
| P0-3 | P0 | DemoApp 타깃 생성/연결 | done | `Examples/SVGSwiftUIDemo` 생성 + xcodebuild build/test 검증 완료 |
| P1-1 | P1 | 모델 타입 정의(`SVGDocument`, `SVGNode`, style/transform) | done | 스켈레톤 구현 |
| P1-2 | P1 | 파서 옵션/에러/인터페이스 정의 | done | 스켈레톤 구현 |
| P1-3 | P1 | 실제 XML tokenization 파서 구현 | done | 지원 요소 트리 파싱 + root/style 기본 파싱 완료 |
| P2-1 | P2 | Path command parser 구현 | done | parser/AST 연결 + `SVGPathCommandBuilder` 완료 |
| P3-1 | P3 | 도형 요소 파싱/Path 변환 | done | `SVGNodePathBuilder`로 rect/circle/ellipse/line/polyline/polygon -> `CGPath` 변환 완료 |
| P4-1 | P4 | 스타일 상속 + override 우선순위 구현 | done | `SVGStyleResolver` 엔진 구현 및 `SVGView` 연동 완료 |
| P5-1 | P5 | AST LRU 캐시 구현/테스트 | done | actor LRU + schemaVersion 포함 cache key + `SVGView` 연동 완료 |
| P6-1 | P6 | SwiftUI 렌더러 구현 | done | Canvas 렌더/스타일 적용 + node/group transform 누적 적용 완료 |
| P7-1 | P7 | Demo 앱 UI(노드 제어/캐시 통계) | done | `SVGCacheMetrics/SVGCacheStats` 추가 + Demo cache 통계 패널/UITest 반영 |
| P7-2 | P7 | Demo UITest 타깃 구성 | done | UITest 5개(시각 회귀 포함) 작성 및 `xcodebuild test` 통과 |
| P7-3 | P7 | 기준 이미지(snapshot baseline) 수집 | done | `UITests/Baselines/iPhone_17/26.2/*.png` 생성 및 저장 |
| P8-1 | P8 | 테스트 확장/회귀 fixture | done | parser/cache/path/style/view/transform 지원 로직 테스트 63개 통과 |
| P8-2 | P8 | UITest 결과 비교(시각 회귀) | done | `testCanvasMatchesBaselines` + diff artifact 출력 + 허용오차 비교 구현 |
| P8-3 | P8 | GitHub CI 파이프라인 | done | `swift test` + Demo UITest 자동 검증 워크플로우 + 안정성 조정 반영 |
| P9-1 | P9 | README/가이드 문서 | done | 설치/예시/노드 제어/캐시/테스트·CI 가이드 정리 |
| P9-2 | P9 | 공개 API 캡슐화 정책 수립/적용 | done | 내부 엔진(parser/model/cache/render helper) `internal` 전환 + 정책 문서화 |

## v2 Milestones
| ID | Phase | Task | Status | Notes |
|---|---|---|---|---|
| A1-1 | A1 | `style` attribute parser | done | declaration parser + `style` 속성 inline 지원 |
| A2-1 | A2 | `<style>` CSS subset parser | done | `<style>` 블록 수집 + selector/rule parser + 문서 반영 |
| A3-1 | A3 | cascade/specificity engine | done | style 규칙 매칭(id/class/element/any), specificity/order 정렬, `inherited -> stylesheet -> node style -> override` 적용 |
| A4-1 | A4 | `data:` URI parser/base64 decoder | done | `data:` URI 파싱/옵션 기반 base64 디코더 유틸 구현 + 8개 회귀 테스트 추가 |
| A5-1 | A5 | embedded SVG recursion 제한 처리 | done | `SVGParser`가 data URI embedded SVG를 임계치 기반으로 post-parse 확장 + max depth/count 제한 구현 |
| A6-1 | A6 | raster image policy 처리 | done | data URI image 정책(`ignore/renderRaster/failOnRaster`) 처리 완료 |
| A7-1 | A7 | v2 cache key versioning | done | parser 옵션/스키마 기반 cache key 분기 검증 강화 |
| A8-1 | A8 | W3C fixture subset 도입(1.1F2/1.2T) | done | `Tests/SVGSwiftUITests/W3C/fixtures` + `w3c-manifest.json` + `A8-2` 연동 전제 정비 |
| A8-2 | A8 | W3C 테스트케이스 자동 생성 스크립트 | done | fixture manifest(`Tests/SVGSwiftUITests/W3C/w3c-manifest.json`) -> `Tests/SVGSwiftUITests/W3CGeneratedTests.swift` 자동 생성/실행 |
| A9-1 | A9 | W3C coverage 리포트 생성 스크립트 | done | pass/fail/unsupported 카테고리별 집계 |
| A9-2 | A9 | CI에 W3C conformance 단계 추가 | done | W3C 전용 테스트/coverage log 및 strict 검증을 CI에서 아티팩트로 업로드 |
| A10-1 | A10 | WebKit LayoutTests 매니페스트/수집 스크립트 기획 | done | `Tests/SVGSwiftUITests/WebKit` 매니페스트 및 동기화 규칙 정리 |
| A10-2 | A10 | WebKit conformance 테스트 생성기/coverage 연동 | done | `testWebKitGeneratedSuite` CI 실행 + strict coverage 검증 포함 |
| A10-3 | A10 | WebKit 후보군 확장 및 CI 게이트 | done | WebKit 후보군을 52건으로 확장하고 expected 전이 규칙을 정비 |
| A11-1 | A11 | `filter` 정의 파싱 및 스타일/리졸버 전달 기초 | done | `filter` 속성/요소를 AST/스타일 경로에 보존 |
| A11-2 | A11 | `filter` 렌더 패스 연동 | done | `filter` primitive(blur/offset) 파싱 결과를 `GraphicsContext` 렌더 체인에 연결 |
| A12 | A12 | filter 고급 primitive 분류 정책 | done | 미지원 primitive(`fe*`) 추적, `manifest`/coverage 정합성 업데이트 완료 |
| A13-1 | A13 | filter 고급 primitive 확장 | done | `feBlend`, `feColorMatrix` 파서/지원 분류 반영 |
| A13-2 | A13 | conformance 정렬 및 커버리지 업데이트 | done | WebKit expected 변경, W3C filter 최소 케이스 추가 및 coverage 재생성 |
| A14-1 | A14 | filter 체인 소스/결과 모델링 | done | `in`/`in2`/`result` 파싱/보존 및 기본값 적용 |
| A14-2 | A14 | filter 체인 렌더 가드 | done | 입력 소스 가용성 검사 기반 `applyFilterPrimitives` 로직 적용 |
| A14-3 | A14 | filter chain 회귀 테스트 강화 | done | WebKit/W3C `in`/`result` 체인 케이스 보강 및 conformance 범위 확장 |

## Stabilization Milestones
| ID | Phase | Task | Status | Notes |
|---|---|---|---|---|
| S1-1 | S1 | 렌더 path 캐시 적용 | done | `SVGView` load 시 shape/path `CGPath` prebuild 및 재사용 |
| S1-2 | S1 | 경로 캐시 오류 경로 정리 | done | 렌더 실패/문서 갱신 시 path cache clear 적용 |
| S2-1 | S2 | clip/mask/filter/masking 우선순위 정리 | done | `docs/ADVANCED_RENDER_FEATURE_ANALYSIS.md` 반영 |
| S2-2 | S2 | `clipPath` 미니멈 구현 설계/구현 | done | `url(#id)` 참조 기반 clipPath 저장/클리핑 적용, inline `style` `clip-path` 반영 |
| S3-1 | S3 | 고해상도/메모리 튜닝 계획 | done | `drawNodes` 캐시 + `pathCache` 임계치 기반 게이팅 적용 |
| S3-2 | S3 | 경계 지점 성능 프로파일 수집/정합성 | done | `SVGRenderPerformanceProfileTests`, profile 스크립트, CI 아티팩트 업로드 |

## Anti-Duplication Rules
1. 작업 시작 전 해당 Task ID를 `in_progress`로 먼저 바꾼다.
2. 구현 후 테스트/검증 커맨드와 결과를 `WORK_LOG.md`에 기록한다.
3. 완료 조건을 모두 충족한 경우에만 `done`으로 변경한다.
4. 동일 Task ID는 재사용하지 않는다(하위 작업은 `-1`, `-2` 증가).
