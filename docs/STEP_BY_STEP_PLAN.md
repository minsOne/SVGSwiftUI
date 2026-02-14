# SVGSwiftUI 단계별 실행 계획표

## 1. 프로젝트 목표
- iOS 15+ 환경에서 SVG를 파싱해 SwiftUI `Path` 기반으로 렌더링한다.
- 노드 단위 제어(색상/크기/offset)를 제공한다.
- 파싱 결과(AST) 캐시를 통해 성능을 개선한다.
- Demo 앱과 테스트 코드를 포함해 개발/검증 루프를 완성한다.
- Demo 앱에 UITest를 추가해 실제 렌더 결과를 기준 이미지와 비교 검증한다.

## 2. 확정된 기본 결정
- 프로젝트 형태: `Swift Package + iOS DemoApp`
- v1 지원 범위: `svg/g/path/rect/circle/ellipse/line/polyline/polygon`
- 노드 제어 방식: `NodeID map` 기본 + 선택적 `resolver closure`
- 캐시 정책: 파싱 결과(AST)만 메모리 LRU 캐시
- v2 확장 범위: `style` 고급 처리 + `data:`(base64) URI 지원

## 3. 단계별 계획 (v1)

| Phase | 작업 | 주요 산출물 | 완료 기준 |
|---|---|---|---|
| P0 | 부트스트랩 | SPM 타깃, DemoApp 연결 구조 | 패키지/앱 빌드 기본 통과 |
| P1 | 모델/파서 골격 | `SVGDocument`, `SVGNode`, 기본 XML 파서 | 샘플 SVG 기본 노드 파싱 성공 |
| P2 | Path 파서 | `M/L/H/V/C/S/Q/T/A/Z` 지원 | path 명령 단위 테스트 통과 |
| P3 | 도형 파서 | rect/circle/ellipse/line/polyline/polygon -> `Path` | 도형별 렌더 테스트 통과 |
| P4 | 스타일/노드 제어 | 상속 스타일 + override(`map/resolver`) | 우선순위 테스트 통과 (`원본 < map < resolver`) |
| P5 | 캐시 | `SVGParseCache` actor, LRU 정책 | hit/miss/eviction 테스트 통과 |
| P6 | 렌더러 | `SVGView` + transform 적용 | 샘플 SVG 시각 확인 가능 |
| P7 | Demo 앱 | 노드 제어 UI + 캐시 통계 화면 + UITest 타깃 | 인터랙션 반영 + 샘플 화면 UITest 실행 가능 |
| P8 | 테스트 강화 | 파서/렌더/캐시/통합 테스트 + 시각 회귀 비교 | `swift test` 통과 + UITest 기준 비교 통과 |
| P9 | 문서화 | README, 지원 범위, 제한 사항 | 신규 사용자가 예제로 실행 가능 |

## 4. 단계별 계획 (v2 고급 기능)

| Phase | 작업 | 주요 산출물 | 완료 기준 |
|---|---|---|---|
| A1 | `style` attribute 파서 | declaration parser | 인라인 style 파싱 테스트 통과 |
| A2 | `<style>` CSS subset | selector/rule AST | id/class/element selector 테스트 통과 |
| A3 | cascade/specificity | style resolver v2 | 우선순위 일치 (`presentation < stylesheet < inline < override`) |
| A4 | `data:` URI 파서 | media type + base64 decoder | 정상/오류 케이스 테스트 통과 |
| A5 | embedded SVG 처리 | `data:image/svg+xml` 재귀 파싱 | depth 제한 포함 통합 테스트 통과 |
| A6 | raster 정책 | `.ignore/.renderRaster/.failOnRaster` | 정책별 동작 테스트 통과 |
| A7 | 캐시 확장 | v2 키 버전 포함 | 옵션/버전 변경 시 stale hit 없음 |

## 5. API 설계 고정안
- `SVGSource`: `.string`, `.data`, `.fileURL`
- `NodeOverrideMap`: `[String: NodeOverride]`
- `NodeStyleResolver`: `(NodeContext) -> NodeOverride?`
- `SVGRenderConfiguration`: `idOverrides`, `resolver`
- `SVGParseCache`(actor): `document(for:)`, `insert`, `removeAll`
- v2 옵션:
  - `enableStyleTag`
  - `enableDataURI`
  - `maxDataURIBytes`
  - `maxEmbeddedImageCount`
  - `imageNodePolicy`

## 6. 위험요소와 대응
- `id` 없는 노드 제어 공백: synthetic key 생성(`auto:/...`)로 보완
- 캐시 오염: `parser/options/schemaVersion` 포함 키로 방지
- arc 정밀도 문제: 허용오차 기반 회귀 테스트로 관리
- base64 메모리 폭증: payload/개수/depth 제한 강제
- CSS 과범위 확장: v2는 subset으로 제한하고 미지원은 로그 처리

## 7. 최종 완료 기준
- v1: iOS 15+에서 샘플 SVG 렌더 + 노드 제어 + 캐시 + 단위/UITest 통과
- v2: style/data URI 고급 기능이 정책 기반으로 안정 동작
- 문서: 지원/미지원/제약이 명확하게 명시됨
