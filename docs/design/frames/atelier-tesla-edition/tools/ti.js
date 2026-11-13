/* 四個圖示:座標 = 車主裁圖(crop-*@6x.png,576 × 576)的像素;1 單位 = 844 寬時 0.0793 px。c = 圓底中心(裁圖上量的),線寬 21(= 1.67 px)。
   form:"owner" = 車主圖上的畫法(主畫面開著、關著都用它);"closed" = 建議版關著的形狀(蓋子放下、門關上、沒有驚嘆號);"front" = 建議版前車廂開著(蓋子畫在車頭那一側)。
   dash = 狀態不明 / 沒有讀值:同一個形狀的短線段虛線、平頭、不填色。 */
const TK = 0.4758 / 6, TSW = 21;
const T_BODY_F = "M151 300 V338 Q151 354 167 354 H173 L185 372 H206 L218 354 H357.5 L369 372 H390 L401.5 354 H407 Q422.5 354 422.5 338 V309 Q422.5 295 409 294.5 L390 294 C378 293 372 287 364 280 C350 268 334 257 308 256 H238 L170 273 Q151 277 151 296 Z";
const T_BODY_T = "M148 300 V337 Q148 353 164 353 H170.5 L182.5 371 H203.5 L215.5 353 H359.5 L371 371 H392 L403.5 353 H410 Q426 353 426 337 V308 Q426 293 412 292.5 L394 292 C382 291 377 286 369 279.5 C355 268 339 256 312 254.5 H235 L167 274 Q148 278 148 297 Z";
const T_LID_F = "M267 254 C285 222 318 176 372 174 C396 173 416 186 428 200";   // 車主的圖:前車廂的蓋子(從車頂中間往右上掀)
const T_LID_T = "M304 250 C326 222 350 186 397 184 C420 183 438 196 450 210";   // 車主的圖:後車廂的蓋子
const T_LID_FRONT = "M270 250 C248 222 224 186 177 184 C154 183 136 196 124 210";   // 建議版:前車廂的蓋子畫在車頭那一側(後車廂的蓋子左右鏡射)
const T_DOOR = "M208.5 388 V262 L224.5 187 Q229.5 166 249 166 H365 Q384 166 384 185 V388 Q384 402.5 369.5 402.5 H223 Q208.5 402.5 208.5 388 Z";
const T_TREAD = "M197 365 H388 V398 Q388 405 381 405 H368 Q364 405 363.500 398 V389 H350.5 V398 Q350.5 405 344 405 H336 Q329.5 405 329.5 398 V389 H318.5 V398 Q318.5 405 312 405 H304 Q297.500 405 297.500 398 V389 H286.5 V398 Q286.5 405 280 405 H272 Q265.5 405 265.5 398 V389 H254.5 V398 Q254.5 405 248 405 H240 Q233.5 405 233.5 398 V389 H221 V398 Q221 405 216 405 H204 Q197 405 197 398 Z";
const T_ARM_L = "M208 178 V200 A118 118 0 0 0 207 364", T_ARM_R = "M376 178 V200 A118 118 0 0 1 377 364";
// 第二十四輪階段 3(只有主畫面用,parts 的第三個參數 rev):關著的前車廂把車頭那一小段填滿、關著的後車廂把車尾那一小段填滿(車身的輪廓裁到 x < 228 / x > 350 填色;虛線時不加);
// 開著的車門往外的那一段加長(端點 (158, 282) → (128, 304))。未選的畫面(四角、建議版並排、照圖的下弧)不帶 rev,維持原樣。
const T_MARK = { frunk: [0, 228], trunk: [350, 576] };
// 每個圖示回一串零件:{ d, closed, at }(描線;at = 另一條線接上來的點,虛線時讓一段實線正好蓋住接點,兩條線才不會在接點旁邊留下不到 2 px 的小縫)、{ fill }(實心)、{ dot: [cx, cy, r] }(實心圓點)
const TI = {
  frunk: { c: [290.3, 285.0], parts: (form, dash, rev) => [{ d: T_BODY_F, closed: 1, at: form === "closed" ? null : [form === "front" ? 270 : 267, 256] }].concat(form === "closed" ? (rev && !dash ? [{ mark: T_BODY_F, clip: T_MARK.frunk, id: "tmF" }] : []) : [{ d: form === "front" ? T_LID_FRONT : T_LID_F }]) },
  trunk: { c: [294.3, 285.5], parts: (form, dash, rev) => [{ d: T_BODY_T, closed: 1, at: form === "closed" ? null : [304, 254.5] }].concat(form === "closed" ? (rev && !dash ? [{ mark: T_BODY_T, clip: T_MARK.trunk, id: "tmT" }] : []) : [{ d: T_LID_T }]) },
  door: { c: [289.4, 289.5], parts: (form, dash, rev) => [{ d: T_DOOR, closed: 1, at: form === "closed" ? null : [209.5, 247] }].concat(form === "closed" ? [] : [{ d: rev ? "M205 247 L128 304" : "M205 247 L158 282" }], [{ d: dash ? "M262 257 H332" : "M240.5 257 H354" }], dash ? [] : [{ dot: [252, 288, 6.5] }]) },   // 關著:沒有左邊那條往外的斜線。虛線時窗台那條線縮短成中間一段(兩端離門框 2.6 px;原本只隔 0.7 px,會被看成不到 2 px 的空)
  tire: { c: [292.9, 289.7], parts: (form, dash) => [{ d: T_ARM_L }, { d: T_ARM_R }].concat(
      dash ? [{ d: "M208 377 H377" }] : (form === "closed" ? [] : [{ d: "M292 220 V276", sw: 26 }, { dot: [292, 317, 14] }]).concat([{ fill: T_TREAD }])) },   // 關著(正常)、沒有讀值:不畫驚嘆號
};
// 虛線(階段 3,裁定 7):1 倍要量得到 ≥ 2 px 的空,而且把 25% 以上的反鋸齒也算成墨。空固定 35 單位(2.78 px;不管落在像素的哪個相位,都至少有兩個像素被墨蓋不到 25%),
// 只調實線段的長度(目標 36 單位 = 2.85 px)讓每條線剛好收尾:封閉的線是整數個週期,不封閉的線頭尾都是實線。線太短放不下一個空的(車門那條斜線)就整段實線。
const T_GAP = 35, T_SEG = 36, T_MIN = 28, T_SEG_REV = 60, T_MIN_REV = 50;   // 第二十四輪階段 3:主畫面的實線段目標加長到 60 單位(4.76 px)、最短 50(ux 畫的就是這一組),空不變;車廂的虛線才看得出是車。未選的畫面維持 36 / 28
// 封閉輪廓的虛線起點(stroke-dashoffset),每個圖示、每種形狀一個:在四角的格位(上排 ∓49°)、1 倍的圖上每 3 單位試一次,挑「沿每一列、每一欄量,線上的空都 ≥ 2 px」的範圍中間
// (前車廂 63–72、後車廂 0–21、車門 3–48;關著的形狀 0–18、0–21、0–48)。換格位或換線寬要重找(tools/offsearch.py)
const T_OFF = { "frunk:owner": 66, "trunk:owner": 9, "door:owner": 24, "frunk:closed": 9, "trunk:closed": 9, "door:closed": 24 };
// 第二十四輪:主畫面「下弧」的格位(前車廂 −117°、車門 −159°、後車廂 +159°)另外找一組(只有關著的形狀;同樣在 1 倍的圖上每 3 單位試一次、挑能過的範圍中間)。
// 換格位、換線寬、換實線段長度都要重找(tools/offsearch.py)
const T_OFF_LOW0 = { "frunk:closed": 9, "trunk:closed": 3, "door:closed": 18 };   // 階段 3 之前(實線段 36)的起點;候選 alt 和 &rev=0 還在用
const T_OFF_LOW = { "frunk:closed": 24, "trunk:closed": 9, "door:closed": 33 };   // 階段 3(實線段 60)重找:前車廂能過的是 12–39、後車廂 0–18、車門 0–69(ux 用 15 試過,三個都在範圍裡);各取中間
const _mp = (() => { const ns = "http://www.w3.org/2000/svg", s = document.createElementNS(ns, "svg"); s.setAttribute("width", 0); s.setAttribute("height", 0); s.setAttribute("aria-hidden", "true"); s.style.position = "absolute";
  const p = document.createElementNS(ns, "path"); s.appendChild(p); document.body.appendChild(s); return p; })();
const _len = {}, plen = (d) => { if (!(d in _len)) { _mp.setAttribute("d", d); _len[d] = _mp.getTotalLength(); } return _len[d]; };
const _at = {}, pathPos = (d, [x, y]) => { const key = d + x + "," + y; if (!(key in _at)) { _mp.setAttribute("d", d); const L = _mp.getTotalLength(); let best = 0, bd = 1e9;
  for (let t = 0; t <= L; t += 1) { const q = _mp.getPointAtLength(t), dd = (q.x - x) ** 2 + (q.y - y) ** 2; if (dd < bd) { bd = dd; best = t; } } _at[key] = best; } return _at[key]; };
const _toff = new URLSearchParams(location.search).get("toff");   // 找虛線起點用(只有量的時候帶)
function tDash(d, closed, at, off0, SEG = T_SEG, MIN = T_MIN) {
  const L = plen(d), per = SEG + T_GAP;
  let n = closed ? Math.max(1, Math.round(L / per)) : Math.max(0, Math.round((L - SEG) / per));
  const seg = () => closed ? L / n - T_GAP : (L - n * T_GAP) / (n + 1);
  while (n > (closed ? 1 : 0) && seg() < MIN) n--;
  if (n === 0) return "";
  const P = seg() + T_GAP, off = !closed ? 0 : _toff !== null ? +_toff : off0 !== undefined ? off0 : at ? (((seg() / 2 - pathPos(d, at)) % P) + P) % P : 0;   // 封閉的線:起點用 T_OFF 搜尋出來的值;沒有的話把一段實線的中點對到接點
  return ` stroke-dasharray="${seg().toFixed(2)} ${T_GAP}"${off ? ` stroke-dashoffset="${off.toFixed(2)}"` : ""}`;
}
// 一個圖示的內容(裁圖座標):線條 fill none、圓頭圓角;虛線時平頭、不畫實心的零件
function tiInner(name, col, o = {}) {
  const dash = !!o.dash;
  return `<g fill="none" stroke="${col}" stroke-width="${TSW}" stroke-linecap="${dash ? "butt" : "round"}" stroke-linejoin="round">` + TI[name].parts(o.form || "owner", dash, !!o.rev).map(p =>
    p.mark ? `<clipPath id="${p.id}"><rect x="${p.clip[0]}" y="0" width="${p.clip[1] - p.clip[0]}" height="576"/></clipPath><path d="${p.mark}" fill="${col}" stroke="none" clip-path="url(#${p.id})"/>` :
    p.fill ? `<path d="${p.fill}" fill="${col}" stroke="none"/>` : p.dot ? `<circle cx="${p.dot[0]}" cy="${p.dot[1]}" r="${p.dot[2]}" fill="${col}" stroke="none"/>` :
    `<path d="${p.d}"${p.sw ? ` stroke-width="${p.sw}"` : ""}${dash ? tDash(p.d, p.closed, p.at, (o.off || T_OFF)[name + ":" + (o.form || "owner")], o.rev ? T_SEG_REV : T_SEG, o.rev ? T_MIN_REV : T_MIN) : ""}/>`).join("") + `</g>`;
}
