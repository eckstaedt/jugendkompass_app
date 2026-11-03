// Picks a deterministic, varied design for a given date.
//
// Same date  -> same design (re-renders after a text edit keep their look).
// Next date  -> different background photo, font, layout and colours.
// A background photo repeats at the earliest after NATURE_IMAGES.length days.

import { readFileSync } from 'node:fs';

export const NATURE_IMAGES = JSON.parse(
  readFileSync(new URL('./nature_images.json', import.meta.url), 'utf8'),
);

// Same font families as vers-des-tages-designer.vercel.app
export const FONTS = {
  playfair: { family: 'Playfair Display', weights: [500, 600, 700, 800] },
  cormorant: { family: 'Cormorant Garamond', weights: [500, 600, 700] },
  ebgaramond: { family: 'EB Garamond', weights: [500, 600, 700] },
  lora: { family: 'Lora', weights: [500, 600, 700] },
  baskerville: { family: 'Libre Baskerville', weights: [400, 700] },
  merriweather: { family: 'Merriweather', weights: [400, 700] },
  plexserif: { family: 'IBM Plex Serif', weights: [400, 500, 600] },
  crimson: { family: 'Crimson Pro', weights: [500, 600, 700] },
  dmserif: { family: 'DM Serif Display', weights: [400] },
  poppins: { family: 'Poppins', weights: [500, 600, 700] },
  montserrat: { family: 'Montserrat', weights: [500, 600, 700] },
  spacegrotesk: { family: 'Space Grotesk', weights: [500, 600, 700] },
  inter: { family: 'Inter', weights: [500, 600, 700] },
  caveat: { family: 'Caveat', weights: [600, 700] },
  bebas: { family: 'Bebas Neue', weights: [400] },
  bigshoulders: { family: 'Big Shoulders Display', weights: [600, 700, 800] },
};

const VERSE_FONTS = Object.keys(FONTS);
const META_FONTS = ['spacegrotesk', 'montserrat', 'inter', 'poppins', 'plexserif', 'lora', 'cormorant'];
// Display fonts that get hard to read for long verses
const SHORT_ONLY = new Set(['bebas', 'bigshoulders', 'caveat']);

export const LAYOUTS = ['center', 'left', 'bottom', 'top', 'frame', 'card', 'quote'];
const OVERLAYS = ['solid', 'gradient', 'vignette', 'tint'];
const TINTS = ['#0E1A2B', '#1B2233', '#2B1D14', '#10261C', '#2A1F33', '#0B1F24'];
const TEXT_COLORS = ['#FFFFFF', '#EDE6D8', '#F7F1E3', '#F2F5F8', '#FFF8EC'];
const META_COLORS = ['#D9B65E', '#D9C99A', '#A8D5C2', '#F2C6A0', '#FFFFFF', '#C9D8F0', '#E8D3A8'];
const REF_STYLES = ['caps', 'dash', 'pill', 'plain'];
const PHOTO_FILTERS = ['none', 'none', 'none', 'soft', 'warm', 'cool', 'mono'];

const EPOCH = Date.UTC(2026, 0, 1);

function dayNumber(isoDate) {
  const [y, m, d] = isoDate.split('-').map(Number);
  return Math.round((Date.UTC(y, m - 1, d) - EPOCH) / 86400000);
}

function mulberry32(seed) {
  let t = seed >>> 0;
  return () => {
    t += 0x6d2b79f5;
    let r = Math.imul(t ^ (t >>> 15), 1 | t);
    r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffled(list, seed) {
  const rnd = mulberry32(seed);
  const copy = [...list];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

const IMAGE_ORDER = shuffled(NATURE_IMAGES, 20260101);
const mod = (n, m) => ((n % m) + m) % m;

export function pickDesign(isoDate, verseLength = 120) {
  const n = dayNumber(isoDate);
  const rnd = mulberry32(n * 2654435761);
  const pick = (list) => list[Math.floor(rnd() * list.length)];

  // Background: walk through a fixed shuffled order -> no repeats for 261 days.
  const cycle = Math.floor(n / IMAGE_ORDER.length);
  const order = cycle === 0 ? IMAGE_ORDER : shuffled(NATURE_IMAGES, 20260101 + cycle);
  const imageId = order[mod(n, order.length)];

  // Font: step through the list with a stride coprime to its length, so two
  // consecutive days never share a font.
  let fontKey = VERSE_FONTS[mod(n * 7, VERSE_FONTS.length)];
  if (verseLength > 170 && SHORT_ONLY.has(fontKey)) {
    fontKey = VERSE_FONTS[mod(n * 7 + 3, VERSE_FONTS.length)];
    if (SHORT_ONLY.has(fontKey)) fontKey = 'lora';
  }
  let metaKey = META_FONTS[mod(n * 3, META_FONTS.length)];
  if (metaKey === fontKey) metaKey = 'spacegrotesk';

  const layout = LAYOUTS[mod(n * 3 + Math.floor(n / LAYOUTS.length), LAYOUTS.length)];
  let overlay = pick(OVERLAYS);
  if (layout === 'bottom' || layout === 'top') overlay = 'gradient';

  const weights = FONTS[fontKey].weights;
  return {
    imageId,
    imageUrl: `https://picsum.photos/id/${imageId}/1080/1080`,
    fontVerse: fontKey,
    familyVerse: FONTS[fontKey].family,
    weightVerse: weights[Math.floor(rnd() * weights.length)],
    fontMeta: metaKey,
    familyMeta: FONTS[metaKey].family,
    weightMeta: FONTS[metaKey].weights[0],
    layout,
    overlay,
    overlayStrength: 0.38 + rnd() * 0.17, // 0.38 – 0.55
    tint: pick(TINTS),
    textColor: pick(TEXT_COLORS),
    metaColor: pick(META_COLORS),
    refStyle: pick(REF_STYLES),
    photoFilter: pick(PHOTO_FILTERS),
    lineHeight: [1.22, 1.3, 1.38][Math.floor(rnd() * 3)],
    quotes: rnd() < 0.5,
    showDate: rnd() < 0.35,
    align: layout === 'left' || layout === 'bottom' || layout === 'top' ? 'left' : 'center',
  };
}
