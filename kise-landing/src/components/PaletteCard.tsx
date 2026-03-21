import { useEffect, useRef, useState } from "react";

// --- Types ---

interface DailyPalette {
  city: string;
  temperature: number;
  condition: string;
  paletteName: string;
  description: string;
  colors: string[];
}

interface Props {
  proxyBaseUrl: string;
}

// --- FNV-1a hash (matches Swift StableHash.fnv1a exactly) ---

function pickTemplateIndex(colors: string[], templateCount: number): number {
  const key = colors.join("");
  let hash = 14695981039346656037n;
  for (const byte of new TextEncoder().encode(key)) {
    hash ^= BigInt(byte);
    hash = BigInt.asUintN(64, hash * 1099511628211n);
  }
  const signed = BigInt.asIntN(64, hash);
  const abs = signed < 0n ? -signed : signed;
  return Number(abs % BigInt(templateCount));
}

// --- Composition templates (ported from CompositionLayout.swift) ---
// Each block: [relativeX, relativeY, relativeWidth, relativeHeight]

type Block = [number, number, number, number];
type Template = Block[];

const TEMPLATES: Record<number, Template[]> = {
  1: [[[0.1, 0.1, 0.8, 0.8]]],
  2: [
    [[0.05, 0.15, 0.65, 0.7], [0.4, 0.05, 0.55, 0.55]],
    [[0.05, 0.3, 0.75, 0.65], [0.3, 0.05, 0.6, 0.45]],
    [[0.1, 0.25, 0.7, 0.65], [0.25, 0.05, 0.55, 0.4]],
    [[0.3, 0.1, 0.65, 0.7], [0.05, 0.25, 0.5, 0.55]],
    [[0.05, 0.05, 0.7, 0.65], [0.3, 0.35, 0.65, 0.6]],
  ],
  3: [
    [[0.1, 0.25, 0.65, 0.55], [0.25, 0.05, 0.5, 0.4], [0.5, 0.6, 0.4, 0.3]],
    [[0.05, 0.2, 0.6, 0.6], [0.3, 0.05, 0.5, 0.35], [0.45, 0.55, 0.45, 0.35]],
    [[0.05, 0.05, 0.75, 0.5], [0.05, 0.4, 0.45, 0.4], [0.4, 0.5, 0.5, 0.35]],
    [[0.05, 0.05, 0.5, 0.75], [0.35, 0.05, 0.55, 0.4], [0.4, 0.55, 0.45, 0.35]],
    [[0.15, 0.15, 0.65, 0.55], [0.05, 0.05, 0.4, 0.35], [0.55, 0.5, 0.35, 0.4]],
  ],
  4: [
    [[0.05, 0.15, 0.55, 0.55], [0.25, 0.05, 0.45, 0.3], [0.45, 0.3, 0.45, 0.35], [0.35, 0.6, 0.35, 0.3]],
    [[0.05, 0.1, 0.55, 0.5], [0.3, 0.05, 0.4, 0.3], [0.45, 0.35, 0.45, 0.35], [0.2, 0.6, 0.4, 0.3]],
    [[0.05, 0.05, 0.5, 0.55], [0.4, 0.2, 0.5, 0.45], [0.1, 0.5, 0.4, 0.35], [0.45, 0.6, 0.35, 0.3]],
    [[0.1, 0.1, 0.55, 0.5], [0.4, 0.05, 0.5, 0.3], [0.05, 0.5, 0.4, 0.35], [0.4, 0.55, 0.45, 0.35]],
    [[0.05, 0.2, 0.6, 0.5], [0.2, 0.05, 0.5, 0.3], [0.45, 0.4, 0.45, 0.3], [0.25, 0.65, 0.35, 0.25]],
  ],
  5: [
    [[0.05, 0.15, 0.5, 0.45], [0.2, 0.05, 0.4, 0.25], [0.45, 0.25, 0.4, 0.3], [0.1, 0.55, 0.35, 0.3], [0.45, 0.6, 0.35, 0.25]],
    [[0.1, 0.1, 0.5, 0.45], [0.45, 0.05, 0.4, 0.25], [0.05, 0.5, 0.35, 0.3], [0.4, 0.35, 0.4, 0.3], [0.3, 0.65, 0.35, 0.25]],
    [[0.05, 0.15, 0.55, 0.4], [0.35, 0.05, 0.45, 0.25], [0.4, 0.3, 0.45, 0.3], [0.05, 0.5, 0.4, 0.35], [0.4, 0.6, 0.4, 0.25]],
  ],
};

// --- Canvas rendering ---

const SCALE = 3;
const CARD_W = 390;
const CARD_H = 520;
const PX_W = CARD_W * SCALE;
const PX_H = CARD_H * SCALE;

const BG = "#F5F3EF";
const TEXT_PRIMARY = "#344E41";
const TEXT_SECONDARY = "#6B6B6B";
const TEXT_TERTIARY = "#9B9B9B";
const BORDER_COLOR = "rgba(0,0,0,0.06)";

const COMP_PAD_X = 24 * SCALE;
const COMP_PAD_TOP = 12 * SCALE;
const COMP_HEIGHT = Math.round(CARD_H * 0.6) * SCALE;
const CORNER_R = 12 * SCALE;

function drawCard(canvas: HTMLCanvasElement, palette: DailyPalette) {
  const ctx = canvas.getContext("2d")!;
  canvas.width = PX_W;
  canvas.height = PX_H;

  // Background with rounded corners
  ctx.beginPath();
  ctx.roundRect(0, 0, PX_W, PX_H, CORNER_R);
  ctx.clip();
  ctx.fillStyle = BG;
  ctx.fillRect(0, 0, PX_W, PX_H);

  // Composition blocks
  const count = Math.min(Math.max(palette.colors.length, 1), 5);
  const templates = TEMPLATES[count] || TEMPLATES[3];
  const idx = pickTemplateIndex(palette.colors, templates.length);
  const blocks = templates[idx];

  const areaX = COMP_PAD_X;
  const areaY = COMP_PAD_TOP;
  const areaW = PX_W - COMP_PAD_X * 2;
  const areaH = COMP_HEIGHT - COMP_PAD_TOP;

  for (let i = 0; i < Math.min(palette.colors.length, blocks.length); i++) {
    const [rx, ry, rw, rh] = blocks[i];
    const x = areaX + rx * areaW;
    const y = areaY + ry * areaH;
    const w = rw * areaW;
    const h = rh * areaH;

    ctx.save();
    ctx.shadowColor = "rgba(0,0,0,0.08)";
    ctx.shadowBlur = 6;
    ctx.shadowOffsetX = 0;
    ctx.shadowOffsetY = 3;
    ctx.fillStyle = palette.colors[i];
    ctx.fillRect(x, y, w, h);
    ctx.restore();
  }

  // Text section below composition
  const textY = COMP_HEIGHT + 24 * SCALE;

  // Palette name
  ctx.textAlign = "center";
  ctx.fillStyle = TEXT_SECONDARY;
  ctx.font = `300 ${13 * SCALE}px "Cormorant Garamond", Georgia, serif`;
  ctx.fillText(palette.paletteName, PX_W / 2, textY);

  // Weather line
  ctx.fillStyle = TEXT_TERTIARY;
  ctx.font = `400 ${11 * SCALE}px "DM Sans", Helvetica, Arial, sans-serif`;
  ctx.fillText(
    `${palette.city} \u00B7 ${palette.temperature}\u00B0C \u00B7 ${palette.condition}`,
    PX_W / 2,
    textY + 18 * SCALE,
  );

  // Brand footer
  const footerY = PX_H - 16 * SCALE;
  const footerPadX = 24 * SCALE;

  ctx.textAlign = "left";
  ctx.fillStyle = TEXT_TERTIARY;
  ctx.font = `400 ${11 * SCALE}px "DM Sans", Helvetica, Arial, sans-serif`;
  ctx.fillText("Vista com inten\u00E7\u00E3o.", footerPadX, footerY);

  ctx.textAlign = "right";
  ctx.fillStyle = TEXT_SECONDARY;
  ctx.font = `300 ${14 * SCALE}px "Cormorant Garamond", Georgia, serif`;
  ctx.fillText("KISE \u7740\u305B", PX_W - footerPadX, footerY);

  // Border
  ctx.beginPath();
  ctx.roundRect(0.5, 0.5, PX_W - 1, PX_H - 1, CORNER_R);
  ctx.strokeStyle = BORDER_COLOR;
  ctx.lineWidth = 1;
  ctx.stroke();
}

function downloadCanvas(canvas: HTMLCanvasElement) {
  canvas.toBlob((blob) => {
    if (!blob) return;
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    const today = new Date().toISOString().slice(0, 10);
    a.download = `kise-pick-${today}.png`;
    a.href = url;
    a.click();
    URL.revokeObjectURL(url);
  }, "image/png");
}

// --- Component ---

export default function PaletteCard({ proxyBaseUrl }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [palette, setPalette] = useState<DailyPalette | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${proxyBaseUrl}/daily-pick`)
      .then((res) => {
        if (!res.ok) throw new Error("No palette available today");
        return res.json() as Promise<DailyPalette>;
      })
      .then(setPalette)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [proxyBaseUrl]);

  useEffect(() => {
    if (!palette || !canvasRef.current) return;
    document.fonts
      .load('300 28px "Cormorant Garamond"')
      .then(() => document.fonts.load('400 14px "DM Sans"'))
      .then(() => drawCard(canvasRef.current!, palette));
  }, [palette]);

  if (loading) {
    return (
      <div className="flex flex-col items-center gap-4 py-12">
        <div
          className="bg-dust/60 animate-pulse rounded-xl"
          style={{ width: 390, height: 520 }}
        />
      </div>
    );
  }

  if (error || !palette) {
    return (
      <div className="flex flex-col items-center gap-2 py-12">
        <p className="font-heading text-xl text-pine/60">
          {error || "No palette available today"}
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center gap-6 py-8">
      <span
        className="font-heading text-sm tracking-widest uppercase"
        style={{ color: TEXT_TERTIARY }}
      >
        KISE'S PICK
      </span>

      <canvas
        ref={canvasRef}
        style={{ width: CARD_W, height: CARD_H, borderRadius: 12 }}
        className="shadow-sm"
      />

      <button
        onClick={() => canvasRef.current && downloadCanvas(canvasRef.current)}
        className="rounded-full border px-7 py-3 text-sm transition-all duration-200 hover:-translate-y-px hover:shadow-md"
        style={{
          borderColor: "#A3B18A",
          color: TEXT_PRIMARY,
          fontFamily: '"DM Sans", Helvetica, Arial, sans-serif',
        }}
      >
        Download PNG
      </button>
    </div>
  );
}
