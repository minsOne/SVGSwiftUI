# SVGSwiftUI API Surface Policy

## 목표
- 외부에 필요한 계약(API)만 `public`으로 유지한다.
- 파서/캐시/렌더 내부 구현은 `internal`로 캡슐화해 변경 비용을 낮춘다.
- OCP 관점에서 확장은 공개 설정 타입/콜백을 통해 수행하고, 내부 타입 노출은 피한다.

## 기본 규칙
1. 기본 접근제어는 `internal`로 둔다.
2. `public`은 외부 앱에서 직접 생성/호출이 필요한 심볼에만 허용한다.
3. 내부 구현 상세(파서 AST, 캐시 구현체, 렌더 빌더)는 `public`로 승격하지 않는다.
4. 새 `public` 심볼 추가 시:
   - 외부 사용 시나리오가 문서화되어야 한다.
   - 대체 불가능성(내부 타입으로는 목적 달성 불가)을 설명해야 한다.
   - 테스트(컴파일/동작)와 문서 업데이트가 함께 포함되어야 한다.

## 현재 공개 API
- 렌더 진입점:
  - `SVGView`
- 입력/옵션:
  - `SVGSource`
  - `SVGParserOptions`
- 오버라이드 계약:
  - `SVGRenderConfiguration`
  - `NodeOverride`
  - `NodeContext`
  - `NodeOverrideMap`
  - `NodeStyleResolver`
- 값 타입:
  - `SVGPaint`, `SVGColor`
  - `SVGSize`, `SVGPoint`
  - `SVGElementKind`

## 내부 캡슐화 대상
- 모델/AST:
  - `SVGDocument`, `SVGNode`, `SVGStyle`, `SVGResolvedStyle`, `SVGTransform`
- 파서:
  - `SVGParser`, `SVGParserError`, `SVGPathDataParser`, `SVGPathCommand`
- 캐시:
  - `SVGParseCache`, `SVGParseCacheKey`
- 렌더 내부:
  - `SVGStyleResolver`, `SVGNodePathBuilder`, `SVGPathCommandBuilder`

## 리뷰 체크리스트
- `rg -n "\bpublic\b" Sources/SVGSwiftUI` 결과에 신규 공개 심볼이 있는가?
- 신규 공개 심볼이 위 "현재 공개 API" 범위를 벗어나는가?
- 벗어난다면 해당 심볼이 꼭 필요한 외부 시나리오가 문서화되어 있는가?
