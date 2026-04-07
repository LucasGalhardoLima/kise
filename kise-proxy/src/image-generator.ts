// kise-proxy/src/image-generator.ts

import satori, { init as initSatori } from "satori/standalone";
import * as fontsData from "./fonts";
import type { DailyContent, DailyPalette, DailyWabiColor, DailyReflection } from "./types";

let yogaInitialized = false;
let resvgInitialized = false;
let ResvgClass: any;

// Helper to convert base64 to ArrayBuffer
function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binaryString = atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

async function getFonts() {
  return [
    { name: "Cormorant Garamond", data: base64ToArrayBuffer(fontsData.CormorantGaramond_Light), weight: 300 as const, style: "normal" as const },
    { name: "DM Sans", data: base64ToArrayBuffer(fontsData.DMSans_Light), weight: 300 as const, style: "normal" as const },
    { name: "DM Sans", data: base64ToArrayBuffer(fontsData.DMSans_Medium), weight: 500 as const, style: "normal" as const },
    { name: "DM Sans", data: base64ToArrayBuffer(fontsData.DMSans_Regular), weight: 400 as const, style: "normal" as const },
    { name: "Noto Sans JP", data: base64ToArrayBuffer(fontsData.NotoSansJP_Light), weight: 300 as const, style: "normal" as const },
  ];
}

/**
 * Initialize yoga + resvg WASM modules.
 * In Workers, pass pre-compiled WebAssembly.Modules from static .wasm imports.
 * In Node.js/tests, pass undefined — we'll load from packages.
 */
export async function initYoga(yogaWasm?: WebAssembly.Module, resvgWasm?: WebAssembly.Module) {
  // Init yoga for satori
  if (!yogaInitialized) {
    if (yogaWasm instanceof WebAssembly.Module) {
      await initSatori(yogaWasm);
    } else {
      const { readFileSync } = await import("fs");
      const { resolve } = await import("path");
      const wasmPath = resolve(import.meta.dirname ?? ".", "../node_modules/satori/yoga.wasm");
      await initSatori(readFileSync(wasmPath));
    }
    yogaInitialized = true;
  }

  // Init resvg for PNG conversion
  if (!resvgInitialized) {
    if (resvgWasm instanceof WebAssembly.Module) {
      const { Resvg, initWasm } = await import("@resvg/resvg-wasm");
      await initWasm(resvgWasm);
      ResvgClass = Resvg;
    } else {
      // Node.js: use native bindings
      const modName = ["@resvg/resvg", "-js"].join("");
      const mod = await import(/* @vite-ignore */ modName);
      ResvgClass = mod.Resvg;
    }
    resvgInitialized = true;
  }
}

/** Generate SVG string from daily content */
export async function generateSvg(content: DailyContent, options: { dark?: boolean } = {}): Promise<string> {
  await initYoga();
  const fonts = await getFonts();
  const vdom = buildVdom(content, options);
  return satori(vdom, { width: 540, height: 540, fonts });
}

/** Generate PNG from daily content — uses resvg (native in tests, WASM in Workers) */
export async function generatePng(content: DailyContent, options: { dark?: boolean } = {}): Promise<Uint8Array> {
  const svg = await generateSvg(content, options);
  await initYoga(); // ensure resvg is initialized too

  const resvg = new ResvgClass(svg, {
    fitTo: { mode: "width", value: 1080 }, // 2x for high-quality
  });

  const pngData = resvg.render();
  return pngData.asPng();
}

function buildVdom(content: DailyContent, options: { dark?: boolean }): any {
  switch (content.type) {
    case "palette":
      return buildPaletteVdom(content, options);
    case "wabi-color":
      return buildWabiVdom(content);
    case "reflection":
      return buildReflectionVdom(content);
  }
}

function buildPaletteVdom(p: DailyPalette, options: { dark?: boolean }) {
  const isDark = options.dark;
  const bgColor = isDark ? "#2C3E35" : "#F5F4F0";
  const textColor = isDark ? "#DAD7CD" : "#344E41";
  const subtextColor = isDark ? "#7A9E7E" : "#A3B18A";
  const hairlineColor = isDark ? "rgba(218,215,205,0.15)" : "rgba(52,78,65,0.06)";

  return {
    type: "div",
    props: {
      style: {
        width: "100%",
        height: "100%",
        backgroundColor: bgColor,
        display: "flex",
        flexDirection: "column",
        position: "relative",
      },
      children: [
        {
          type: "div",
          props: {
            style: {
              position: "absolute",
              top: 66,
              left: 0,
              width: "100%",
              height: 1,
              backgroundColor: hairlineColor,
            },
          },
        },
        {
          type: "div",
          props: {
            style: {
              position: "absolute",
              top: 0,
              right: 72,
              width: 1,
              height: "100%",
              backgroundColor: hairlineColor,
            },
          },
        },
        {
          type: "div",
          props: {
            style: {
              position: "absolute",
              top: 28,
              right: 32,
              display: "flex",
              alignItems: "baseline",
            },
            children: [
              {
                type: "span",
                props: {
                  style: {
                    fontFamily: "Cormorant Garamond",
                    fontSize: 14,
                    color: textColor,
                    letterSpacing: "0.15em",
                    opacity: 0.5,
                  },
                  children: "KISE",
                },
              },
              {
                type: "span",
                props: {
                  style: {
                    fontSize: 10,
                    color: textColor,
                    marginLeft: 4,
                    opacity: 0.35,
                  },
                  children: "着せ",
                },
              },
            ],
          },
        },
        {
          type: "div",
          props: {
            style: {
              position: "absolute",
              top: 28,
              left: 32,
              fontFamily: "Cormorant Garamond",
              fontSize: 20,
              color: textColor,
              opacity: 0.65,
            },
            children: p.poeticNameLocal,
          },
        },
        {
          type: "div",
          props: {
            style: {
              flex: 1,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              position: "relative",
            },
            children: [
              {
                type: "div",
                props: {
                  style: {
                    width: 200,
                    height: 160,
                    backgroundColor: p.colors[0],
                    transform: "rotate(-2deg)",
                  },
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    position: "absolute",
                    width: 140,
                    height: 120,
                    left: 260,
                    top: 100,
                    backgroundColor: p.colors[1],
                    transform: "rotate(3deg)",
                  },
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    position: "absolute",
                    width: 110,
                    height: 90,
                    left: 100,
                    top: 220,
                    backgroundColor: p.colors[2],
                    transform: "rotate(-1deg)",
                  },
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    position: "absolute",
                    width: 90,
                    height: 80,
                    left: 300,
                    top: 260,
                    backgroundColor: p.colors[3],
                    transform: "rotate(4deg)",
                  },
                },
              },
            ],
          },
        },
        {
          type: "div",
          props: {
            style: {
              padding: "0 32px 28px",
              display: "flex",
              flexDirection: "column",
            },
            children: [
              {
                type: "div",
                props: {
                  style: {
                    fontSize: 10,
                    fontFamily: "DM Sans",
                    fontWeight: 500,
                    letterSpacing: "0.2em",
                    color: subtextColor,
                    marginBottom: 4,
                  },
                  children: p.city.toUpperCase(),
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    fontFamily: "Cormorant Garamond",
                    fontSize: 38,
                    color: textColor,
                    marginBottom: 3,
                  },
                  children: `${p.temperature}°`,
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    fontSize: 11,
                    fontFamily: "DM Sans",
                    fontWeight: 300,
                    color: isDark ? "#7A9E7E" : "#588157",
                    marginBottom: 14,
                  },
                  children: p.condition,
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    fontSize: 9,
                    fontFamily: "DM Sans",
                    fontWeight: 300,
                    color: isDark ? "rgba(218,215,205,0.35)" : "#A3B18A",
                    letterSpacing: "0.08em",
                  },
                  children: p.colors.join(" · "),
                },
              },
            ],
          },
        },
      ],
    },
  };
}

function buildWabiVdom(c: DailyWabiColor) {
  const isLight = isLightColor(c.hex);
  const textColor = isLight ? "#344E41" : "#F5F4F0";
  const subtextColor = isLight ? "rgba(52,78,65,0.5)" : "rgba(245,244,240,0.5)";

  return {
    type: "div",
    props: {
      style: {
        width: "100%",
        height: "100%",
        backgroundColor: c.hex,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        position: "relative",
      },
      children: [
        {
          type: "div",
          props: {
            style: {
              position: "absolute",
              top: 28,
              right: 32,
              display: "flex",
              alignItems: "baseline",
            },
            children: [
              {
                type: "span",
                props: {
                  style: {
                    fontFamily: "Cormorant Garamond",
                    fontSize: 14,
                    color: textColor,
                    letterSpacing: "0.15em",
                    opacity: 0.5,
                  },
                  children: "KISE",
                },
              },
              {
                type: "span",
                props: {
                  style: {
                    fontSize: 10,
                    color: textColor,
                    marginLeft: 4,
                    opacity: 0.35,
                  },
                  children: "着せ",
                },
              },
            ],
          },
        },
        {
          type: "div",
          props: {
            style: {
              fontFamily: "Cormorant Garamond",
              fontSize: 72,
              color: textColor,
              opacity: 0.9,
            },
            children: c.kanji,
          },
        },
        {
          type: "div",
          props: {
            style: {
              position: "absolute",
              bottom: 28,
              left: 32,
              display: "flex",
              flexDirection: "column",
            },
            children: [
              {
                type: "div",
                props: {
                  style: {
                    fontFamily: "DM Sans",
                    fontSize: 11,
                    color: subtextColor,
                    letterSpacing: "0.1em",
                  },
                  children: c.romanization,
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    fontFamily: "DM Sans",
                    fontSize: 9,
                    color: subtextColor,
                    letterSpacing: "0.08em",
                    marginTop: 4,
                  },
                  children: c.hex,
                },
              },
            ],
          },
        },
      ],
    },
  };
}

function buildReflectionVdom(r: DailyReflection) {
  return {
    type: "div",
    props: {
      style: {
        width: "100%",
        height: "100%",
        backgroundColor: "#E8E6E0",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 60,
      },
      children: [
        {
          type: "div",
          props: {
            style: {
              fontFamily: "Cormorant Garamond",
              fontSize: 26,
              lineHeight: 1.6,
              color: "#344E41",
              textAlign: "center",
            },
            children: r.text,
          },
        },
      ],
    },
  };
}

function isLightColor(hex: string): boolean {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5;
}
