import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const DEFAULT_WIDTH = 360;
const DEFAULT_HEIGHT = 300;

const args = parseArgs(process.argv.slice(2));
const manifestPath = resolvePath(
    args.manifest ?? "Scripts/browser-oracle/browser-oracle-manifest.json"
);
const outputDirectory = resolvePath(
    args.output ?? "Examples/SVGSwiftUIDemo/UITests/BrowserBaselines"
);
const referenceBaselineDirectory = args.referenceBaselineDir
    ? resolvePath(args.referenceBaselineDir)
    : null;
const manifest = loadJSON(manifestPath);
const entries = Array.isArray(manifest.cases) ? manifest.cases : [];
const topN = parsePositiveInt(args.topN);
if (entries.length === 0) {
    throw new Error(`No cases found in manifest: ${manifestPath}`);
}

const orderedEntries = Array.from(entries)
    .map((entry, index) => ({
        ...entry,
        __index: index,
        __priority: normalizePriority(entry.priority, index)
    }))
    .sort((lhs, rhs) => {
        const lhsPriority = lhs.__priority;
        const rhsPriority = rhs.__priority;
        if (lhsPriority !== rhsPriority) {
            return lhsPriority - rhsPriority;
        }
        return lhs.__index - rhs.__index;
    });

const selectedEntries = topN && topN > 0
    ? orderedEntries.slice(0, topN)
    : orderedEntries;

await fs.promises.mkdir(outputDirectory, { recursive: true });
const browser = await chromium.launch({ headless: true });
const baseDir = path.dirname(manifestPath);
const page = await browser.newPage();

try {
    for (const entry of selectedEntries) {
        if (!entry.name || !entry.svg) {
            throw new Error(
                `Invalid manifest entry: name and svg are required. Entry=${JSON.stringify(entry)}`
            );
        }

        const svgPath = resolvePath(entry.svg, baseDir);
        const svgContent = await fs.promises.readFile(svgPath, "utf8");

        const viewport = resolveViewport({
            declared: entry.size,
            svgText: svgContent,
            referenceBaselineDirectory,
            baselineName: entry.name,
            outputDirectory,
            fallbackWidth: DEFAULT_WIDTH,
            fallbackHeight: DEFAULT_HEIGHT
        });

        const imageWidth = viewport.width;
        const imageHeight = viewport.height;
        await page.setViewportSize({ width: imageWidth, height: imageHeight });
        const html = makeHTMLPage({
            width: imageWidth,
            height: imageHeight,
            svgText: svgContent,
            backgroundColor: entry.backgroundColor ?? "#f7f7f7"
        });

        await page.setContent(html, { waitUntil: "domcontentloaded" });
        await page.waitForSelector("#canvas-root", { state: "visible" });
        await applyOverrides(page, {
            targetNodeID: entry.targetNodeID,
            overrides: entry.overrides ?? {}
        });

        const outputPath = path.join(outputDirectory, `${entry.name}.png`);
        await page.locator("#canvas-root").screenshot({ path: outputPath, type: "png" });
        console.log(`Generated browser baseline: ${outputPath}`);
    }
} finally {
    await page.close();
    await browser.close();
}

function normalizePriority(rawValue, fallbackIndex) {
    if (Number.isInteger(rawValue) && rawValue >= 0) {
        return rawValue;
    }
    return fallbackIndex;
}

function parsePositiveInt(value) {
    if (typeof value !== "string") {
        return null;
    }
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
        return null;
    }
    return parsed;
}

function parseArgs(rawArgs) {
    const result = {};
    for (let index = 0; index < rawArgs.length; index += 1) {
        const arg = rawArgs[index];
        if (!arg.startsWith("--")) {
            continue;
        }
        const isEq = arg.includes("=");
        if (isEq) {
            const [name, value] = arg.split("=", 2);
            result[name.slice(2)] = value ?? "";
            continue;
        }
        const key = arg.slice(2);
        const next = rawArgs[index + 1];
        if (!next || next.startsWith("--")) {
            result[key] = "true";
            continue;
        }
        index += 1;
        result[key] = next;
    }
    return result;
}

function resolvePath(value, base = process.cwd()) {
    if (path.isAbsolute(value)) {
        return path.normalize(value);
    }
    return path.normalize(path.join(base, value));
}

function resolveViewport({
    declared,
    svgText,
    referenceBaselineDirectory,
    baselineName
}) {
    const declaredWidth = toPositiveInteger(declared?.width);
    const declaredHeight = toPositiveInteger(declared?.height);

    if (declaredWidth && declaredHeight) {
        return { width: declaredWidth, height: declaredHeight };
    }

    if (referenceBaselineDirectory) {
        const referencePath = path.join(referenceBaselineDirectory, `${baselineName}.png`);
        const referenceSize = readPNGSize(referencePath);
        if (referenceSize) {
            return referenceSize;
        }
    }

    const svgWidth = parseDimensionFromSVG(svgText, "width");
    const svgHeight = parseDimensionFromSVG(svgText, "height");
    return {
        width: toPositiveInteger(svgWidth, DEFAULT_WIDTH),
        height: toPositiveInteger(svgHeight, DEFAULT_HEIGHT)
    };
}

function parseDimensionFromSVG(svgText, attributeName) {
    const regex = new RegExp(
        `${attributeName}\\s*=\\s*(['\"])` +
        `([^'"]+)\\1`,
        "i"
    );
    const match = svgText.match(regex);
    if (!match) {
        return null;
    }
    return match[2];
}

function toPositiveInteger(value, fallback = null) {
    if (typeof value !== "number") {
        if (typeof value !== "string") {
            return fallback;
        }
        const parsed = Number.parseFloat(value);
        if (!Number.isFinite(parsed) || parsed <= 0) {
            return fallback;
        }
        return Math.max(1, Math.trunc(parsed));
    }
    if (!Number.isFinite(value) || value <= 0) {
        return fallback;
    }
    return Math.max(1, Math.trunc(value));
}

function loadJSON(filePath) {
    const raw = fs.readFileSync(filePath, "utf8");
    return JSON.parse(raw);
}

function readPNGSize(filePath) {
    if (!fs.existsSync(filePath)) {
        return null;
    }
    const data = fs.readFileSync(filePath);
    if (data.length < 24 || data.readUInt32BE(0) !== 0x89504e47) {
        return null;
    }
    const width = data.readUInt32BE(16);
    const height = data.readUInt32BE(20);
    if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
        return null;
    }
    return { width, height };
}

function makeHTMLPage({ width, height, svgText, backgroundColor }) {
    return `<!doctype html>
<html>
    <head>
        <meta charset="utf-8"/>
        <style>
            html, body {
                margin: 0;
                width: ${width}px;
                height: ${height}px;
                background: ${backgroundColor};
            }
            #canvas-root {
                width: ${width}px;
                height: ${height}px;
                background: ${backgroundColor};
                border: 1px solid rgba(0, 0, 0, 0.1);
                border-radius: 12px;
                box-sizing: border-box;
                overflow: hidden;
                display: flex;
                justify-content: center;
                align-items: center;
            }
            #canvas-root svg {
                width: 100%;
                height: 100%;
            }
        </style>
    </head>
    <body>
        <div id="canvas-root">
            ${svgText}
        </div>
    </body>
</html>`;
}

async function applyOverrides(page, { targetNodeID, overrides }) {
    await page.evaluate((payload) => {
        const fill = payload.overrides?.fill;
        const stroke = payload.overrides?.stroke;
        const strokeWidth = payload.overrides?.strokeWidth;
        const scale = payload.overrides?.scale;
        const offset = payload.overrides?.offset;
        const targetNode = payload.targetNodeID
            ? document.getElementById(payload.targetNodeID)
            : null;

        if (!targetNode) {
            return;
        }
        if (fill) {
            targetNode.setAttribute("fill", fill);
        }
        if (stroke) {
            targetNode.setAttribute("stroke", stroke);
            targetNode.setAttribute("stroke-width", String(strokeWidth ?? 1));
        }

        const sx = Number(scale?.width);
        const sy = Number(scale?.height);
        const hasScale = Number.isFinite(sx) && Number.isFinite(sy) && (sx !== 1 || sy !== 1);
        const dx = Number(offset?.x);
        const dy = Number(offset?.y);
        const hasOffset = Number.isFinite(dx) && Number.isFinite(dy) && (dx !== 0 || dy !== 0);

        if (!hasScale && !hasOffset) {
            return;
        }

        const transformParts = [];
        const existing = targetNode.getAttribute("transform");
        if (existing && existing.trim().length > 0) {
            transformParts.push(existing.trim());
        }

        if (hasScale) {
            const bounds = targetNode.getBBox();
            if (bounds.width > 0 && bounds.height > 0) {
                const cx = bounds.x + bounds.width / 2;
                const cy = bounds.y + bounds.height / 2;
                transformParts.push(`translate(${cx}, ${cy}) scale(${sx}, ${sy}) translate(${-cx}, ${-cy})`);
            }
        }
        if (hasOffset) {
            transformParts.push(`translate(${dx}, ${dy})`);
        }

        if (transformParts.length > 0) {
            targetNode.setAttribute("transform", transformParts.join(" "));
        }
    }, { targetNodeID, overrides });
}
