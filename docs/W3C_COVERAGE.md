# W3C Conformance Coverage
Generated: 2026-02-15 16:06:05Z UTC
Manifest: `Tests/SVGSwiftUITests/W3C/w3c-manifest.json`
- Total fixtures: 12
- Missing SVG resources: 0
- Missing reference resources: 0

## Expected Status Summary
| Suite | Category | Total | Pass | Fail | Unsupported | Missing SVG | Missing Reference |
|---|---|---:|---:|---:|---:|---:|---:|
| 1.1F2 | coords | 1 | 1 | 0 | 0 | 0 | 0 |
| 1.1F2 | filter | 4 | 4 | 0 | 0 | 0 | 0 |
| 1.1F2 | paths | 1 | 1 | 0 | 0 | 0 | 0 |
| 1.1F2 | shapes | 2 | 2 | 0 | 0 | 0 | 0 |
| 1.1F2 | styling | 2 | 2 | 0 | 0 | 0 | 0 |
| 1.2T | coords | 1 | 1 | 0 | 0 | 0 | 0 |
| 1.2T | styling | 1 | 1 | 0 | 0 | 0 | 0 |

## Coverage by Expected Result
| Result | Count | Coverage |
|---|---:|---:|
| pass | 12 | 100.0% |
| fail | 0 | 0.0% |
| unsupported | 0 | 0.0% |

## Conformance Health Check
- Invalid fixture mode values: 0
- Invalid fixture expected values: 0
- Empty fixture IDs: 0
- Duplicate fixture IDs: 0
- Strict mode: enabled

## Fixture Table
| ID | Suite | Category | Mode | Expected | SVG | Reference | SVG Resource | Reference Resource |
|---|---|---|---|---|---|---|---|---|
| w3c-1.1F2-coords-skew-transform | 1.1F2 | coords | parse | pass | `fixtures/1.1F2/svg/coords-skew-transform.svg` | `fixtures/1.1F2/ref/coords-skew-transform.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-shapes-rounded-rect | 1.1F2 | shapes | parse | pass | `fixtures/1.1F2/svg/shapes-rounded-rect.svg` | `fixtures/1.1F2/ref/shapes-rounded-rect.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-paths-move-line | 1.1F2 | paths | parse | pass | `fixtures/1.1F2/svg/paths-move-line.svg` | `fixtures/1.1F2/ref/paths-move-line.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-filters-blend-01-b-min | 1.1F2 | filter | parse | pass | `fixtures/1.1F2/svg/filters-blend-01-b-min.svg` | `fixtures/1.1F2/ref/filters-blend-01-b-min.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-filters-colormatrix-01-b-min | 1.1F2 | filter | parse | pass | `fixtures/1.1F2/svg/filters-colormatrix-01-b-min.svg` | `fixtures/1.1F2/ref/filters-colormatrix-01-b-min.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-filters-chain-01-b-min | 1.1F2 | filter | parse | pass | `fixtures/1.1F2/svg/filters-chain-01-b-min.svg` | `fixtures/1.1F2/ref/filters-chain-01-b-min.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-filters-composite-arithmetic-01-b-min | 1.1F2 | filter | parse | pass | `fixtures/1.1F2/svg/filters-composite-arithmetic-01-b-min.svg` | `fixtures/1.1F2/ref/filters-composite-arithmetic-01-b-min.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-shapes-rect-circle | 1.1F2 | shapes | parse | pass | `fixtures/1.1F2/svg/shapes-rect-circle.svg` | `fixtures/1.1F2/ref/shapes-rect-circle.expected.txt` | ✅ | ✅ |
| w3c-1.2T-coords-relative-transform | 1.2T | coords | parse | pass | `fixtures/1.2T/svg/coords-relative-transform.svg` | `fixtures/1.2T/ref/coords-relative-transform.expected.txt` | ✅ | ✅ |
| w3c-1.2T-styling-fill-stroke | 1.2T | styling | parse | pass | `fixtures/1.2T/svg/styling-fill-stroke.svg` | `fixtures/1.2T/ref/styling-fill-stroke.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-styling-stroke-capjoin | 1.1F2 | styling | parse | pass | `fixtures/1.1F2/svg/styling-stroke-capjoin.svg` | `fixtures/1.1F2/ref/styling-stroke-capjoin.expected.txt` | ✅ | ✅ |
| w3c-1.1F2-styling-fillrule-dash | 1.1F2 | styling | parse | pass | `fixtures/1.1F2/svg/styling-fillrule-dash.svg` | `fixtures/1.1F2/ref/styling-fillrule-dash.expected.txt` | ✅ | ✅ |

- pass/fail/unsupported are derived from manifest `expected` field.
- Unsupported coverage should be reviewed against runtime parser capability after implementation progress.

## Strict Mode Validation
- strict mode failed: false
