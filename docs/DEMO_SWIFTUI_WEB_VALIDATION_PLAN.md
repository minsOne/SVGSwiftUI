# SVG Demo 확장 검증 계획 (Session 61+)

## 목표
- 현재 DemoApp의 SVG 샘플 셋을 다각도로 확장한다.
- 노드 단위 제어(색상/크기/offset/투명도/스케일/애니메이션)를 실제 UI 조작으로 검증한다.
- SwiftUI 렌더 결과를 브라우저 기준 렌더와 비교해 정량적으로 정합성을 점검한다.
- W3C/WebKit conformance 범위와의 연결 고리를 유지하면서, 회귀 방지를 위한 반복 가능한 체크포인트를 만든다.

## 실행 원칙
- UI에서 사람이 조작 가능한 최소 단위(버튼/슬라이더/토글)로 테스트를 구성한다.
- 샘플 확장, 테스트 추가, 검증 스크립트, 로그/리포트를 한 세트로 묶는다.
- 중복 작업 방지 위해 `TASK_BOARD`/`WORK_CONTINUATION`/`WORK_LOG` 동기화 후 단계 종료 시 커밋한다.

## 단계별 계획표

| 단계 | 작업 항목 | 세부 작업 | 산출물 | 완료 기준 |
|---|---|---|---|---|
| 1 | 샘플 메타셋 확장 | 기존 `SVG` 리소스 중 20건 목표 선정. 신규 케이스를 카테고리별로 등록 (Transform/Filter/Style/Dense/Complex/Animation/Geometry). 각 샘플에 `defaultNodeID`, `category`, `notes`, `overrideTargets`(기본 제어 대상 노드) 추가. | `Examples/SVGSwiftUIDemo/Sources/SampleSVG.swift`, `Resources/*.svg` | 샘플 20건 중 75% 이상이 id 기반 node override가 가능한 구조 | 
| 2 | 노드 제어 UI 확장 | Demo 카드에 최소 공통 제어 추가: 스케일 슬라이더, offset X/Y 슬라이더, 불투명도, 색상 토글(컬러 스왑), 애니메이션 토글. 선택 노드를 기준으로 `NodeOverrideMap` 생성 로직 분리. | `Examples/SVGSwiftUIDemo/Sources/ContentView.swift`, `Demo` 접근성 ID 정리 | 각 제어가 sample별로 동작하고 접근성 ID(`demo.control.*`)가 안정적으로 노출 |
| 3 | NodeOverride 회귀 테스트(단위/통합) | 샘플 모델에서 `overrideTargets` 기반으로 최소 1개 노드에 대한 `SVGRenderConfiguration` 생성 검증 테스트 추가. 렌더 전후 변경 전파를 `SVGView` 캡처 비교로 검증할 수 있게 테스트 헬퍼 준비. | `Tests/SVGSwiftUITests/*` | 오버라이드가 nil이 아닌 실제 map으로 생성되는지 단위 검증 |
| 4 | Demo UITest 확대 | 기존 `SVGView` 렌더 검사에 다음 케이스 추가: 1) 복수 샘플 캔버스 존재 2) 노드 제어 토글/슬라이더 조작 3) 조작 전후 캔처 해시/차이율 검증 4) 코드 펼치기/기본정보 표시 유지 | `Examples/SVGSwiftUIDemo/UITests/SVGSwiftUIDests.swift` | 새 테스트 케이스 5개 이상 추가, iOS simulator 기준 통과 |
| 5 | 웹 기준 비교 확장 | Playwright 기반 기준 이미지 생성 대상 확장: 신규 샘플 전부 또는 우선순위 Top 12 케이스만 채택. viewport/백그라운드 고정 플래그 적용. | `Scripts/browser-oracle/*.mjs`, `Scripts/browser-oracle/browser-oracle-manifest.json` | `SVG_BROWSER_REFERENCE_DIR` 모드로 신규 샘플까지 `xcodebuild` + `swift test` 비교 가능 |
| 6 | Web 기준 대조 자동화 | CI에서 브라우저 기준 생성 또는 업로드 산출물을 기반으로 `testCanvasMatchesBaselines` 확장. 실패 시 diff 이미지 저장. | `.github/workflows/ci.yml` + `Examples/.../UITests/Baselines` | CI 통과 기준: mismatch ≤ tolerance, diff artifact 1건도 누락 없음 |
| 7 | Conformance 연계 | 신규 샘플의 대응되는 W3C/WebKit 후보를 `w3c-manifest` / `webkit-manifest` 또는 브라우저 오라클 카테고리에 최소 1개씩 매핑. unsupported 분류 키를 fixture 주석으로 명시. | `Tests/SVGSwiftUITests/W3C/*`, `Tests/SVGSwiftUITests/WebKit/*`, `Scripts/*` | strict 모드 기반 커버리지 리포트에 신규 케이스 반영 |
| 8 | 통계/문서 갱신 | `docs/WORK_LOG`, `WORK_CONTINUATION`, `TASK_BOARD` 업데이트 후 커밋. | `docs/*` | 다음 세션에서 즉시 이어갈 수 있는 상태, 중복 작업 포인트 없음 |

## 우선순위
1. 1~4단계: Demo 실행성과 노드 제어 기반 UI 검증 루프 확립  
2. 5~6단계: 브라우저 기준 비교 자동화로 시각 정합성 증명  
3. 7단계: conformance/manifest 정합성 연결  

## 검증 커맨드(요약)
- `swift test --no-parallel`  
- `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test`  
- `./Scripts/browser-oracle/generate-browser-baselines.sh --manifest Scripts/browser-oracle/browser-oracle-manifest.json --output Examples/SVGSwiftUIDemo/UITests/BrowserBaselines`  
- `SVG_BROWSER_REFERENCE_DIR=Examples/SVGSwiftUIDemo/UITests/BrowserBaselines SVG_BROWSER_REFERENCE_TOLERANCE=2 xcodebuild ... test`  
- `./Scripts/w3c/w3c-coverage.sh ...` / `./Scripts/webkit/webkit-coverage.sh ...` (변경 시)

## 리스크
- iOS/Simulator와 브라우저 antialiasing 차이로 작은 픽셀 오차 발생(튜닝 필요).
- 노드 조작 테스트에서 접근성 ID 변경은 테스트 안정성에 직접 영향.
- 신규 샘플이 너무 무거운 경우 데모/UITest 타임아웃 가능성.

## 완료 선언 조건
- 샘플 20개 중 핵심 12개 이상이 웹 기준+Demo UITest에서 "렌더 존재 + 노드 제어 적용 + baseline 비교" 3개 지표를 모두 통과.
- Task/Commit/Log가 일치하며, 동일 샘플이 중복 등록되지 않음.
