import zlib from "node:zlib";
import { writeFileSync } from "node:fs";

const SIZE = 1024;
// Brand colors
const midnight = [11, 20, 55];      // #0B1437
const gold = [201, 169, 110];       // #C9A96E

// Geometry (waxing crescent + a small astroid star)
const cx = 512, cy = 524, R = 344;
const carveX = 656, carveY = 452, rCarve = 332;
const starX = 556, starY = 632, starS = 60;

function dist(ax, ay, bx, by) { return Math.hypot(ax - bx, ay - by); }
function inCrescent(x, y) {
  return dist(x, y, cx, cy) <= R && dist(x, y, carveX, carveY) >= rCarve;
}
function inStar(x, y) {
  // Astroid (4-cusped) star: |dx/s|^(2/3) + |dy/s|^(2/3) <= 1
  const dx = Math.abs(x - starX) / starS;
  const dy = Math.abs(y - starY) / starS;
  return Math.pow(dx, 2 / 3) + Math.pow(dy, 2 / 3) <= 1;
}
function isGold(x, y) { return inCrescent(x, y) || inStar(x, y); }

// 3x3 supersampling for anti-aliasing
const offs = [-1 / 3, 0, 1 / 3];
const raw = Buffer.alloc(SIZE * SIZE * 3); // RGB, opaque (iOS icons reject alpha)
for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    let hits = 0;
    for (const oy of offs) for (const ox of offs) if (isGold(x + 0.5 + ox, y + 0.5 + oy)) hits++;
    const c = hits / 9;
    const i = (y * SIZE + x) * 3;
    raw[i] = Math.round(midnight[0] * (1 - c) + gold[0] * c);
    raw[i + 1] = Math.round(midnight[1] * (1 - c) + gold[1] * c);
    raw[i + 2] = Math.round(midnight[2] * (1 - c) + gold[2] * c);
  }
}

// --- minimal PNG encoder (RGBA, filter 0) ---
const crcTable = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const td = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td), 0);
  return Buffer.concat([len, td, crc]);
}
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0); ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
// filtered scanlines (filter byte 0 per row)
const stride = SIZE * 3;
const filtered = Buffer.alloc((stride + 1) * SIZE);
for (let y = 0; y < SIZE; y++) {
  filtered[y * (stride + 1)] = 0;
  raw.copy(filtered, y * (stride + 1) + 1, y * stride, y * stride + stride);
}
const idat = zlib.deflateSync(filtered, { level: 9 });
const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk("IHDR", ihdr), chunk("IDAT", idat), chunk("IEND", Buffer.alloc(0)),
]);
writeFileSync(process.argv[2], png);
console.log("wrote", process.argv[2], png.length, "bytes");
