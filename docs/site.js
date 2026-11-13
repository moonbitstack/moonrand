/* The tassel hangs at the edge of the code; drag it down and the rest comes into view.
   It adds no wrapper element — a wrapper would change the grid and the code box would
   grow. The fringe is drawn as SVG rather than a striped background: threads crowd at
   the bound waist, then hang before they let go, no two the same length, all of them
   fading along one gradient at the tips. */
const TASSEL_W = 20;
const TASSEL_H = 58;

function tasselMarkup(){
  const cx = TASSEL_W / 2;
  const y1 = 15.2;
  let threads = "";
  const n = 13;
  for (let i = 0; i < n; i++){
    const t = i / (n - 1);                        /* 0 left tip → 1 right tip */
    const jitter = ((i * 7) % 5) / 4;             /* a little apart, so it is not a comb */
    const x1 = cx + (t - 0.5) * 5.2;              /* at the waist: tucked under the collar */
    const x2 = cx + (t - 0.5) * (15.4 + jitter * 1.8);
    const y2 = 47.6 + jitter * 5.2 - Math.abs(t - 0.5) * 2.4;
    /* hang first, splay later: the control points hug the centre line */
    const c = "C" + (x1 + (x2 - x1) * 0.24).toFixed(2) + " " + (y1 + (y2 - y1) * 0.36).toFixed(2) + " " +
      (x1 + (x2 - x1) * 0.66).toFixed(2) + " " + (y1 + (y2 - y1) * 0.74).toFixed(2) + " ";
    threads += '<path d="M' + x1.toFixed(2) + " " + y1 + " " + c +
      x2.toFixed(2) + " " + y2.toFixed(2) + '" stroke="url(#tS)" stroke-width="' +
      (0.6 + jitter * 0.12).toFixed(2) + '" stroke-linecap="round" fill="none"/>';
  }
  return '<svg viewBox="0 0 ' + TASSEL_W + " " + TASSEL_H + '" aria-hidden="true">' +
    "<defs>" +
      '<linearGradient id="tC" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="6.4">' +
        '<stop offset="0" stop-color="#2E5887" stop-opacity=".12"/>' +
        '<stop offset="1" stop-color="#2E5887" stop-opacity=".62"/>' +
      "</linearGradient>" +
      '<radialGradient id="tB" cx=".34" cy=".26" r=".82">' +
        '<stop offset="0" stop-color="#C2D4E8"/>' +
        '<stop offset=".5" stop-color="#3C639B"/>' +
        '<stop offset="1" stop-color="#14253B"/>' +
      "</radialGradient>" +
      '<linearGradient id="tS" gradientUnits="userSpaceOnUse" x1="0" y1="14" x2="0" y2="52">' +
        '<stop offset="0" stop-color="#1B3A63" stop-opacity=".86"/>' +
        '<stop offset=".42" stop-color="#2A4E82" stop-opacity=".82"/>' +
        '<stop offset=".72" stop-color="#38609A" stop-opacity=".68"/>' +
        '<stop offset=".90" stop-color="#4270A4" stop-opacity=".34"/>' +
        '<stop offset="1" stop-color="#4270A4" stop-opacity=".02"/>' +
      "</linearGradient>" +
      '<filter id="tD" x="-60%" y="-40%" width="220%" height="200%">' +
        '<feDropShadow dx="0" dy=".7" stdDeviation=".55" flood-color="#16283F" flood-opacity=".22"/>' +
      "</filter>" +
    "</defs>" +
    '<g filter="url(#tD)">' +
    /* the cord: down from the top edge, gaining colour only near the knot */
    '<path d="M' + cx + ' 0V7" stroke="url(#tC)" stroke-width=".9" fill="none"/>' +
    /* the bead: one porcelain bead, its highlight up and to the left */
    '<circle cx="' + cx + '" cy="9.2" r="2.4" fill="url(#tB)"/>' +
    /* the collar: one pressed line, holding the fringe at the waist */
    '<rect x="' + (cx - 3) + '" y="12.3" width="6" height="2.3" rx=".6" fill="#23477F"/>' +
    '<path d="M' + (cx - 2.6) + ' 12.9h5.2" stroke="#A8C0DC" stroke-width=".38" stroke-opacity=".55"/>' +
    threads +
    "</g>" +
  "</svg>";
}

function wireTassels(){
  document.querySelectorAll(".tassel").forEach(function(t){ t.remove(); });
  document.querySelectorAll(".code").forEach(function(code){
    const mx = code.scrollWidth - code.clientWidth;
    const my = code.scrollHeight - code.clientHeight;
    if (mx < 4 && my < 4) return;

    /* Hang it from the section, not from the code's own box: a box that scrolls
       clips what is inside it, and half the tassel lies to the left of the binding. */
    const host = code.closest("section") || code.parentElement;
    if (getComputedStyle(host).position === "static") host.style.position = "relative";
    const horizontal = mx >= my;

    const t = document.createElement("span");
    t.className = "tassel";
    t.tabIndex = 0;
    t.setAttribute("role", "slider");
    t.setAttribute("aria-orientation", "vertical");
    t.setAttribute("aria-label", "pull to read the rest");
    t.innerHTML = tasselMarkup();
    host.appendChild(t);

    const cr = code.getBoundingClientRect();
    const hr = host.getBoundingClientRect();
    const left = cr.left - hr.left - 20;
    const top0 = cr.top - hr.top + 12;
    let p = 0;
    const travel = function(){ return Math.max(1, code.clientHeight - 26 - TASSEL_H); };
    const paint = function(){
      t.style.left = left + "px";
      t.style.top = (top0 + p * travel()) + "px";
      t.setAttribute("aria-valuenow", Math.round(p * 100));
    };
    const seek = function(v){
      p = Math.max(0, Math.min(1, v));
      if (horizontal) code.scrollLeft = p * (code.scrollWidth - code.clientWidth);
      else code.scrollTop = p * (code.scrollHeight - code.clientHeight);
      paint();
    };
    code.addEventListener("scroll", function(){
      if (horizontal){
        const m = code.scrollWidth - code.clientWidth;
        p = m > 0 ? code.scrollLeft / m : 0;
      } else {
        const m = code.scrollHeight - code.clientHeight;
        p = m > 0 ? code.scrollTop / m : 0;
      }
      paint();
    });

    let dragging = false, y0 = 0, p0 = 0;
    t.addEventListener("pointerdown", function(e){
      dragging = true; y0 = e.clientY; p0 = p;
      try { t.setPointerCapture(e.pointerId); } catch (err) {}
      t.classList.add("is-live");
      e.preventDefault();
    });
    t.addEventListener("pointermove", function(e){
      if (!dragging) return;
      seek(p0 + (e.clientY - y0) / travel());
    });
    const stop = function(e){
      if (!dragging) return;
      dragging = false;
      t.classList.remove("is-live");
      try { t.releasePointerCapture(e.pointerId); } catch (err) {}
    };
    t.addEventListener("pointerup", stop);
    t.addEventListener("pointercancel", stop);
    t.addEventListener("keydown", function(e){
      if (e.key === "ArrowDown" || e.key === "ArrowRight"){ seek(p + .08); e.preventDefault(); }
      else if (e.key === "ArrowUp" || e.key === "ArrowLeft"){ seek(p - .08); e.preventDefault(); }
    });
    paint();
  });
}

/* ── Colouring the guide's blocks ───────────────
   The blocks are plain text in the page, so they copy and read as written; the
   colour is painted here, from one pass over the text. Comments, strings,
   numbers, package aliases and keywords only — nothing is inferred. */
(function(){
  var KEYWORDS = /\b(?:pub|priv|fn|let|mut|struct|enum|impl|trait|for|in|while|if|else|match|return|break|guard|test|async|raise|catch|true|false|type|open|extern|derive|self|Self)\b/;
  var TOKEN = /(\/\/[^\n]*)|(b?"(?:[^"\\]|\\.)*")|(@[A-Za-z_][A-Za-z0-9_]*)|(\b\d[\d_]*(?:\.\d+)?(?:[A-Za-z]{1,3})?\b)|(\b(?:pub|priv|fn|let|mut|struct|enum|impl|trait|for|in|while|if|else|match|return|break|guard|test|async|raise|catch|true|false|type|open|extern|derive)\b)/g;

  function paint(el){
    var text = el.textContent;
    if (!KEYWORDS.test(text) && text.indexOf('"') < 0) return;
    var out = '', last = 0, m;
    TOKEN.lastIndex = 0;
    while ((m = TOKEN.exec(text)) !== null){
      out += escapeHtml(text.slice(last, m.index));
      var cls = m[1] ? 'c' : m[2] ? 's' : m[3] ? 'p' : m[4] ? 'n' : 'k';
      out += '<span class="' + cls + '">' + escapeHtml(m[0]) + '</span>';
      last = m.index + m[0].length;
    }
    out += escapeHtml(text.slice(last));
    el.innerHTML = out;
  }

  function escapeHtml(s){
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  document.querySelectorAll('pre.gcode > code').forEach(paint);

  /* ── Which section is on screen ─────────────── */
  var links = {};
  document.querySelectorAll('.ref__side a, .guide__toc a').forEach(function(a){
    var id = (a.getAttribute('href') || '').replace(/^#/, '');
    if (id) links[id] = a;
  });
  var targets = Object.keys(links).map(function(id){ return document.getElementById(id); }).filter(Boolean);
  if (targets.length){
    var mark = function(){
      var best = null, bestTop = Infinity;
      targets.forEach(function(t){
        var top = t.getBoundingClientRect().top;
        if (top < 120 && Math.abs(top) < bestTop){ best = t; bestTop = Math.abs(top); }
      });
      Object.keys(links).forEach(function(id){ links[id].classList.toggle('is-here', !!best && best.id === id); });
    };
    addEventListener('scroll', mark, { passive: true });
    mark();
  }
})();
