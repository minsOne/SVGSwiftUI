# S3 Performance Tuning Plan

## 목적
- `S3-1`의 성능 목표를 코드 수정만큼 구체적인 임계치로 정리한다.
- 고해상도/대형 SVG에서 렌더 재연산 비용과 메모리 사용량이 급증하지 않도록 기준을 남긴다.

## 1) 1차 성능 개선 항목 (이미 적용)
- `SVGView`에서 `resolver`가 없는 정적 구성일 때 `drawNodes`를 캐시한다.
- 캐시 키는 `SVGRenderConfigurationSignature`로 구성한다.
  - 정렬된 `idOverrides` 항목 기반
  - `resolver` 존재 여부 기반
- `styleResolver.resolve`와 트리 순회가 frame 단위에서 반복되지 않도록 제거한다.

## 2) 실제 적용한 수치화 정책
- `SVGView`에서 `drawNodes` 캐시 사용 여부는 아래 임계치로 결정한다.
  - `drawable node count <= 2,000`
  - `source byte size <= 300_000`
- 임계치 미만 문서는 정적 구성(`resolver == nil`)에서만 `drawNodes` 캐시를 사용한다.
- 임계치 초과 문서는 메모리 안정성 위해 `drawNodes` 캐시를 비활성화한다.
- 대형 문서 진입 임계치:
  - `drawable node count > 2,000` 또는 `document bytes > 300 KB`일 때 메모리 점검
- 임계치 경계(`==`)는 캐시 허용(`<=`)으로 동작함.
- 메모리 추적:
  - 동일 문서 on/off 변경 시 `cachedDrawNodes.count` 안정성
  - 임계치 초과 문서에서 캐시 삭제/재생성 횟수 추적

## 3) 메모리 가드 정책(적용)
- `drawNodes` 캐시 정책 외에도 `pathCache` 캐시를 동일 임계치로 게이팅한다.
  - `SVGRenderCachePolicy.shouldCachePathCache(for:sourceByteCount:)`:
    - `drawable node count <= 2,000`
    - `source byte size <= 300_000`
  - 임계치 초과 시 `pathCache`를 비워서 메모리 보유량을 감소시키고,
    `buildDrawNodes`에서 각 노드 경로를 렌더 시점에 필요 시 생성한다.
- 정책은 기존 `S3-1`의 `canCacheDrawNodesForCurrentDocument`와 함께 운영되며,
  문서 상태가 변할 때마다 갱신한다.

## 4) CI 반영
- 기존 CI `swift test` + conformance 단계는 유지한다.
- `swift test --parallel`과 `--no-parallel` 조합 결과를 동일 문서 집합에서 비교해
  - `S3-1` 변경이 안정성/재현성에 미치는 영향을 모니터한다.
- `S3 성능 프로파일` 단계 추가
  - `Scripts/performance/run-s3-profile.sh` 실행으로 boundary 문서(2000/2001 nodes, 300000/300001 bytes) `measure` 로그를 수집
  - CI에서 `s3-profile.log`를 아티팩트로 보관하여 임계치 정합성 판단 근거로 사용

## 5) 측정 근거
- 기준 시나리오:
  - 노드 임계치 경계: `2_000` vs `2_001`
  - 바이트 임계치 경계: `300_000` vs `300_001`
- 정량 지표:
  - `SVGRenderPerformanceProfileTests`에서 `measure`로 수집한 wall-clock 기준 실행 시간
  - `shouldCache*` 결정값 + 실제 렌더 경로 경유 `CGPath` 건수

### 측정 실행 결과 반영
- 정식 임계치 조정 시 `S3_PERFORMANCE_TUNING.md` 하위 섹션에 기준 시점/기기/실행 옵션을 함께 기록한다.

## 6) 완료 조건
- S3-1 리포트:
  - 구현된 캐시 경로와 미적용 경로의 동작이 테스트로 구분되어야 한다.
  - 세션 로그에 임계치/판단 기준이 반영되어야 한다.
  - CI에서 기존 conformance pass를 유지해야 한다.
