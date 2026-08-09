import { readFile } from "node:fs/promises";
import path from "node:path";

/**
 * Font loading for the generated OG images.
 *
 * The Newsreader faces are committed to `assets/fonts` as woff (satori, behind
 * `next/og`, reads woff but cannot decompress woff2). Keeping them in the repo
 * means the OG images render identically on any machine and the build never
 * depends on Google Fonts being reachable. The browser still gets its copies
 * from `next/font/google` — these two files are build-time only.
 */

type Face = {
  name: string;
  data: ArrayBuffer;
  style: "normal" | "italic";
  weight: 400;
};

const FONT_DIR = path.join(process.cwd(), "assets", "fonts");

async function loadFace(file: string) {
  const buffer = await readFile(path.join(FONT_DIR, file));
  return buffer.buffer.slice(
    buffer.byteOffset,
    buffer.byteOffset + buffer.byteLength,
  ) as ArrayBuffer;
}

export async function newsreaderFonts(): Promise<Face[]> {
  const [normal, italic] = await Promise.all([
    loadFace("Newsreader-Regular.woff"),
    loadFace("Newsreader-Italic.woff"),
  ]);

  return [
    { name: "Newsreader", data: normal, style: "normal", weight: 400 },
    { name: "Newsreader", data: italic, style: "italic", weight: 400 },
  ];
}

/** Paper & Fire, in the few values an OG image needs. */
export const OG = {
  size: { width: 1200, height: 630 },
  contentType: "image/png",
  paper: "#F7F4EE",
  ink: "#161513",
  low: "#B3AFA6",
  mid: "#8A867D",
  accent: "#FF6B2C",
  ember: "#FF7A18",
  peach: "#F9E4D8",
  mint: "#DCEFE2",
} as const;
