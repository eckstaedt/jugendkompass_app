// Runs INSIDE the browser page (Playwright). Draws one verse image on a
// 1080×1080 canvas – same approach as vers-des-tages-designer.vercel.app
// (nature photo + darkening + auto-fitted verse + reference), but with a
// different layout/typography per day. Returns a JPEG data URL.
//
// eslint-disable-next-line no-unused-vars
async function drawVerseImage({ verse, reference, dateLabel, design: d, imageDataUrl }) {
  const S = 1080;
  const canvas = document.createElement('canvas');
  canvas.width = S;
  canvas.height = S;
  const ctx = canvas.getContext('2d');

  const fontSpec = (w, size, fam) => `${w} ${size}px "${fam}"`;
  await document.fonts.load(fontSpec(d.weightVerse, 48, d.familyVerse));
  await document.fonts.load(fontSpec(d.weightMeta, 32, d.familyMeta));
  await document.fonts.ready;

  const img = await new Promise((resolve, reject) => {
    const el = new Image();
    el.onload = () => resolve(el);
    el.onerror = reject;
    el.src = imageDataUrl;
  });

  const rgba = (hex, a) => {
    const h = hex.replace('#', '');
    return `rgba(${parseInt(h.slice(0, 2), 16)},${parseInt(h.slice(2, 4), 16)},${parseInt(h.slice(4, 6), 16)},${a})`;
  };

  // ---------- background ----------
  const filters = {
    none: 'none',
    soft: 'saturate(0.85) contrast(0.95)',
    warm: 'sepia(0.25) saturate(1.1)',
    cool: 'saturate(0.8) hue-rotate(-8deg)',
    mono: 'grayscale(1) contrast(1.05)',
  };
  function drawCover(context, filter) {
    const ir = img.width / img.height;
    let sx = 0, sy = 0, sw = img.width, sh = img.height;
    if (ir > 1) { sw = img.height; sx = (img.width - sw) / 2; } else { sh = img.width; sy = (img.height - sh) / 2; }
    context.save();
    context.filter = filter;
    context.drawImage(img, sx, sy, sw, sh, 0, 0, S, S);
    context.restore();
  }
  drawCover(ctx, filters[d.photoFilter] || 'none');

  const a = d.overlayStrength;
  if (d.overlay === 'solid') {
    ctx.fillStyle = `rgba(0,0,0,${a})`;
    ctx.fillRect(0, 0, S, S);
  } else if (d.overlay === 'tint') {
    ctx.fillStyle = rgba(d.tint, a + 0.05);
    ctx.fillRect(0, 0, S, S);
  } else if (d.overlay === 'vignette') {
    ctx.fillStyle = `rgba(0,0,0,${a * 0.7})`;
    ctx.fillRect(0, 0, S, S);
    const g = ctx.createRadialGradient(S / 2, S / 2, S * 0.2, S / 2, S / 2, S * 0.75);
    g.addColorStop(0, 'rgba(0,0,0,0)');
    g.addColorStop(1, `rgba(0,0,0,${Math.min(0.85, a + 0.3)})`);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, S, S);
  } else {
    // gradient – strongest where the text sits
    const top = d.layout === 'top';
    const g = ctx.createLinearGradient(0, top ? 0 : S, 0, top ? S : 0);
    g.addColorStop(0, `rgba(0,0,0,${Math.min(0.85, a + 0.35)})`);
    g.addColorStop(0.55, `rgba(0,0,0,${a * 0.75})`);
    g.addColorStop(1, `rgba(0,0,0,${a * 0.25})`);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, S, S);
  }

  // ---------- text block geometry ----------
  let box; // {x, y, w, h}
  switch (d.layout) {
    case 'left': box = { x: 130, y: 150, w: S - 260, h: S - 300 }; break;
    case 'bottom': box = { x: 100, y: 430, w: S - 200, h: S - 430 - 110 }; break;
    case 'top': box = { x: 100, y: 110, w: S - 200, h: S - 110 - 430 }; break;
    case 'frame': box = { x: 150, y: 160, w: S - 300, h: S - 320 }; break;
    case 'card': box = { x: 170, y: 190, w: S - 340, h: S - 380 }; break;
    case 'quote': box = { x: 140, y: 230, w: S - 260, h: S - 400 }; break;
    default: box = { x: 120, y: 120, w: S - 240, h: S - 240 };
  }

  const alreadyQuoted = /^[„“"»«‚]/.test(verse);
  const text = d.quotes && !alreadyQuoted ? `„${verse}“` : verse;
  const words = text.split(/\s+/).filter(Boolean);
  const metaSize = 33;
  const metaBlock = metaSize * (d.showDate ? 2.9 : 1.6) + 40;
  const isCaps = d.fontVerse === 'bebas' || d.fontVerse === 'bigshoulders';

  function wrap(size) {
    ctx.font = fontSpec(d.weightVerse, size, d.familyVerse);
    const space = ctx.measureText(' ').width;
    const lines = [];
    let line = [];
    let width = 0;
    for (const w of words) {
      const ww = ctx.measureText(isCaps ? w.toUpperCase() : w).width;
      if (line.length && width + space + ww > box.w) {
        lines.push(line.join(' '));
        line = [w];
        width = ww;
      } else {
        width += (line.length ? space : 0) + ww;
        line.push(w);
      }
    }
    if (line.length) lines.push(line.join(' '));
    return lines;
  }
  let size = isCaps ? 120 : 104;
  let lines = wrap(size);
  while (size > 22) {
    lines = wrap(size);
    if (lines.length * size * d.lineHeight <= box.h - metaBlock) break;
    size -= 2;
  }
  const lineH = size * d.lineHeight;
  const blockH = lines.length * lineH + metaBlock;

  let y0;
  if (d.layout === 'bottom') y0 = box.y + box.h - blockH;
  else if (d.layout === 'top') y0 = box.y;
  else y0 = box.y + (box.h - blockH) / 2;

  // ---------- decorations behind the text ----------
  if (d.layout === 'card') {
    const pad = 54;
    const r = 40;
    const cx = box.x - pad, cy = y0 - pad, cw = box.w + pad * 2, ch = blockH + pad * 2 - 20;
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(cx, cy, cw, ch, r);
    ctx.clip();
    drawCover(ctx, 'blur(22px) brightness(0.75)');
    ctx.fillStyle = 'rgba(0,0,0,0.28)';
    ctx.fillRect(cx, cy, cw, ch);
    ctx.restore();
    ctx.strokeStyle = 'rgba(255,255,255,0.22)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(cx, cy, cw, ch, r);
    ctx.stroke();
  }
  if (d.layout === 'frame') {
    ctx.strokeStyle = rgba(d.metaColor, 0.7);
    ctx.lineWidth = 2;
    ctx.strokeRect(60, 60, S - 120, S - 120);
    ctx.strokeStyle = rgba(d.metaColor, 0.35);
    ctx.strokeRect(74, 74, S - 148, S - 148);
  }
  if (d.layout === 'quote') {
    ctx.save();
    ctx.font = `700 360px "${d.familyVerse}"`;
    ctx.fillStyle = rgba(d.metaColor, 0.35);
    ctx.textBaseline = 'alphabetic';
    ctx.fillText('“', 90, y0 + 95);
    ctx.restore();
  }
  if (d.layout === 'left') {
    ctx.fillStyle = rgba(d.metaColor, 0.9);
    ctx.fillRect(box.x - 40, y0 + 6, 5, lines.length * lineH - 12);
  }

  // ---------- verse ----------
  ctx.save();
  ctx.shadowColor = 'rgba(0,0,0,0.45)';
  ctx.shadowBlur = 18;
  ctx.shadowOffsetY = 2;
  ctx.fillStyle = d.textColor;
  ctx.font = fontSpec(d.weightVerse, size, d.familyVerse);
  ctx.textBaseline = 'alphabetic';
  const left = d.align === 'left';
  ctx.textAlign = left ? 'left' : 'center';
  const tx = left ? box.x : S / 2;
  let y = y0 + size * 0.88;
  for (const l of lines) {
    ctx.fillText(isCaps ? l.toUpperCase() : l, tx, y);
    y += lineH;
  }
  ctx.restore();

  // ---------- reference (+ optional date) ----------
  let my = y0 + lines.length * lineH + 40 + metaSize * 0.4;
  ctx.save();
  ctx.shadowColor = 'rgba(0,0,0,0.4)';
  ctx.shadowBlur = 10;
  ctx.textAlign = left ? 'left' : 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = d.metaColor;
  const mx = left ? box.x : S / 2;
  let refText = reference;
  if (d.refStyle === 'caps') refText = reference.toUpperCase();
  if (d.refStyle === 'dash') refText = `— ${reference}`;
  ctx.font = fontSpec(d.weightMeta, metaSize, d.familyMeta);
  if (d.refStyle === 'caps') ctx.letterSpacing = '3px';

  if (d.refStyle === 'pill') {
    const w = ctx.measureText(refText).width + 56;
    const h = metaSize + 26;
    const px = left ? mx : mx - w / 2;
    ctx.shadowBlur = 0;
    ctx.fillStyle = 'rgba(0,0,0,0.30)';
    ctx.beginPath();
    ctx.roundRect(px, my - h / 2, w, h, h / 2);
    ctx.fill();
    ctx.strokeStyle = rgba(d.metaColor, 0.8);
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = d.metaColor;
    ctx.fillText(refText, left ? mx + 28 : mx, my + 1);
  } else {
    if (d.refStyle === 'caps' || d.refStyle === 'plain') {
      // small divider like the designer
      ctx.save();
      ctx.globalAlpha = 0.6;
      ctx.strokeStyle = d.metaColor;
      ctx.lineWidth = 2;
      ctx.beginPath();
      const dx = left ? mx : mx - 36;
      ctx.moveTo(dx, my - 30);
      ctx.lineTo(dx + 72, my - 30);
      ctx.stroke();
      ctx.restore();
      my += 6;
    }
    ctx.fillText(refText, mx, my);
  }
  if (d.showDate && dateLabel) {
    ctx.letterSpacing = '1px';
    ctx.globalAlpha = 0.8;
    ctx.font = fontSpec(d.weightMeta, Math.round(metaSize * 0.75), d.familyMeta);
    ctx.fillText(dateLabel, mx, my + metaSize * 1.45);
  }
  ctx.restore();

  return canvas.toDataURL('image/jpeg', 0.88);
}
