/* Pirate Chain Stats page. Data: /stats/stats.json (every minute), /stats/history.json (hourly). */
(function () {
  'use strict';

  var C = {c1: '#b08b3e', c2: '#4a7fe0', c3: '#2c9c73', c4: '#9168d4', c5: '#c56d43', muted: '#6f7590', surface: '#202033'};
  var HEAT = ['#71603a', '#8c7540', '#a88b47', '#c4a256', '#e0c07a'];   // validated single-hue ramp
  var ORDER = ['ironwood', 'chain', 'supply', 'network', 'upgrade', 'price', 'privacy', 'activity', 'heatmap', 'records', 'embed'];
  var WINDOWS = ['10blocks', '24h', '7d', '30d', 'total'];
  var WIN_LABELS = {'10blocks': '10 Blocks', '24h': '24h', '7d': '7d', '30d': '30d', 'total': 'Total'};
  var ROWS = [
    ['n_zz', 'z→z Shielded Trx', 'Fully shielded transactions: no transparent inputs or outputs, so sender, receiver and amount are all hidden. The old pages called this "Total Shielded Trx".', true],
    ['unspent_change', 'Anonset (unspent)', 'Change in the unspent anonset: Sapling outputs minus Sapling spends in the period. This is the "Anonset" row of the original anonset.dexstats.info page.', true],
    ['new_notes', 'New Notes', 'Notes added to the note trees in the period (Sapling outputs + Ironwood actions), i.e. growth of "Anonset (all notes)".'],
    ['ironwood_actions', 'Ironwood Actions', 'Actions in the new Ironwood pool. Each action is one spend and one output, either of which may be padding.'],
    ['n_shielding', 'Shielding Trx', 'Transparent → shielded, e.g. miners and notaries moving coinbase or dPoW funds into the shielded pool.'],
    ['n_deshielding', 'Deshielding Trx', 'Shielded → transparent.'],
    ['n_transparent', 'Transparent Trx', 'Fully transparent transactions (not coinbase). On Pirate these are notary node dPoW transactions; users can\'t send transparently.'],
    ['n_coinbase', 'Coinbase Trx', 'Mining reward transactions, one per block.'],
    ['ntx', 'All Transactions', 'Every transaction in the period.']
  ];
  var POOLS = [['sapling', 'Sapling', C.c1], ['transparent', 'Transparent', C.c2], ['ironwood', 'Ironwood', C.c3], ['sprout', 'Sprout (locked)', C.c5]];
  var CANONICAL = 'https://explorer.piratechain.com';
  var DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  var S = null, H = null, D = null;          // stats, history, prepared daily series
  var focusId = null, openedByClick = false, focusRange = '1y';

  // ---------- formatting ----------
  function $(id) { return document.getElementById(id); }
  function el(tag, cls, text) { var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
  function num(v, d) { return v == null || isNaN(v) ? '–' : Number(v).toLocaleString('en-US', {maximumFractionDigits: d || 0, minimumFractionDigits: d && Math.abs(v) < 1 ? Math.min(d, 2) : 0}); }
  function compact(v, d) {
    if (v == null || isNaN(v)) return '–';
    var a = Math.abs(v), units = [[1e12, 'T'], [1e9, 'B'], [1e6, 'M'], [1e3, 'K']];
    for (var i = 0; i < units.length; i++) if (a >= units[i][0]) return (v / units[i][0]).toFixed(d == null ? (a / units[i][0] >= 100 ? 0 : 1) : d).replace(/\.0$/, '') + units[i][1];
    return a < 10 && a % 1 ? v.toFixed(2) : String(Math.round(v));
  }
  function pct(v, d) { return v == null ? '–' : v.toFixed(d == null ? (v < 1 ? 2 : 1) : d) + '%'; }
  function arrr(v) { return num(v) + ' ARRR'; }
  function usd(v) { return v == null ? '–' : '$' + (v < 10 ? v.toFixed(4) : num(v)); }
  function hashrate(s) { if (s == null) return '–'; var u = ['sols/s', 'Ksols/s', 'Msols/s', 'Gsols/s'], i = 0; while (s >= 1000 && i < 3) { s /= 1000; i++; } return s.toFixed(2) + ' ' + u[i]; }
  function ago(ts) {
    var s = Math.max(0, Math.round(Date.now() / 1000 - ts));
    if (s < 90) return s + ' s ago'; if (s < 5400) return Math.round(s / 60) + ' min ago';
    if (s < 172800) return Math.round(s / 3600) + ' h ago'; return Math.round(s / 86400) + ' days ago';
  }
  var MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  function fmtDay(ms, withYear) { var d = new Date(ms); return MON[d.getUTCMonth()] + ' ' + d.getUTCDate() + (withYear ? ', ' + d.getUTCFullYear() : ''); }
  function fmtTime(ms) { var d = new Date(ms); return fmtDay(ms) + ' ' + String(d.getUTCHours()).padStart(2, '0') + ':00 UTC'; }
  function blockLink(h, text) { var a = el('a', null, text || num(h)); a.href = '/block-index/' + h; return a; }

  // ---------- data ----------
  function prepareDaily() {
    var d = H.daily, n = d.day.length;
    // while the history scan runs, only show the unbroken recent stretch of full days
    var start = 0;
    if (!H.coverage.complete) {
      start = n - 1;
      while (start > 0 && d.blocks[start - 1] >= 1000) start--;
    }
    var out = {x: []};
    Object.keys(d).forEach(function (k) { if (k !== 'day') out[k] = d[k].slice(start); });
    out.x = d.day.slice(start).map(function (s) { return Date.parse(s + 'T00:00:00Z'); });
    out.partial = true;   // the last day is today, still running
    return out;
  }

  function load() {
    fetch('/stats/stats.json', {cache: 'no-store'})
      .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
      .then(function (d) { $('error').hidden = true; S = d; render(); if (focusId) renderFocus(false); if (!booted) { booted = true; syncHash(); } })
      .catch(function (e) { $('error').hidden = false; $('error').textContent = "Can't load stats: " + e.message; });
  }
  function loadHistory() {
    fetch('/stats/history.json', {cache: 'no-store'})
      .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
      .then(function (h) { H = h; D = prepareDaily(); renderHistory(); if (focusId) renderFocus(false); })
      .catch(function () { /* charts stay empty; live figures still work */ });
  }
  var booted = false;

  // ---------- main page ----------
  function setText(id, t) { var e = $(id); if (e) e.textContent = t; }
  function render() {
    var d = S;
    var stale = Date.now() / 1000 - d.updated > 1800;
    var live = $('live');
    live.className = 'live' + (stale ? ' stale' : '');
    live.lastChild.textContent = '';
    live.lastChild.append('Block ', el('b', null, num(d.height)), ' · updated ' + ago(d.updated) + (stale ? ' · data is stale' : ''));

    setText('kAnonset', compact(d.anonsetTotal));
    setText('kShielded', pct(d.shieldedPercent, 2));
    setText('kZz', num(d.activity['24h'].n_zz));
    setText('kZzSub', 'fully shielded z→z · ' + num(d.activity['24h'].ntx) + ' tx total');
    setText('kPrice', d.prices ? '$' + d.prices.usd.toFixed(4) : '–');

    setText('height', num(d.height));
    setText('reward', d.reward + ' ARRR');
    setText('nextReward', d.nextReward + ' ARRR');
    var hv = $('halving'); hv.textContent = num(d.nextHalvingHeight);
    hv.append(el('div', 'sub', '~' + fmtDay(d.nextHalvingEta * 1000, true)), el('div', 'countdown'));
    tickCountdown();
    setText('notarized', num(d.notarized));
    setText('circulating', arrr(d.circulating));
    setText('locked', arrr(d.locked));
    setText('totalSupply', arrr(d.supply));
    setText('maxSupply', arrr(d.maxSupply));
    setText('minedPct', pct(100 * d.supply / d.maxSupply));
    if (d.emission) {
      setText('newPerDay', num(d.emission.newPerDay) + ' ARRR');
      setText('inflation', d.emission.inflationPercent.toFixed(3) + '% / year');
      setText('finalSupply', '≈ ' + num(d.emission.finalSupply) + ' ARRR');
    }
    if (d.upgrade && d.upgrade.peers) {
      var u = d.upgrade, stuck = u.versions.filter(function (v) { return !v.ready; }).reduce(function (a, v) { return a + v.peers; }, 0);
      setText('upReady', pct(u.readyPercent, 0) + ' (' + u.ready + ' of ' + u.peers + ')');
      setText('upStuck', stuck + ' peer' + (stuck === 1 ? '' : 's'));
      var top = u.versions.slice().sort(function (a, b) { return b.peers - a.peers; })[0];
      setText('upTop', top.version + ' · ' + top.peers + ' peers');
      var ub = $('upBar'), ul = $('upLegend'); ub.textContent = ''; ul.textContent = '';
      [[u.ready, 'Ironwood-ready (6.0+)', C.c3], [u.peers - u.ready, 'Older (stuck)', C.c5]].forEach(function (s) {
        if (!s[0]) return; var seg = el('div'); seg.style.flex = String(s[0]); seg.style.background = s[2]; seg.title = s[1] + ': ' + s[0]; ub.append(seg);
        var it = el('span'), sw = el('i'); sw.style.background = s[2]; it.append(sw, s[1] + ' ' + s[0]); ul.append(it);
      });
    }
    setText('nethash', hashrate(d.networkSolps));
    setText('difficulty', num(d.difficulty, 2));
    setText('blocktime', d.avgBlockSeconds.toFixed(1) + ' s');
    setText('peers', [d.peersSeen.day, d.peersSeen.week, d.peersSeen.month].map(function (v) { return num(v); }).join(' / '));
    var p = d.prices, m = d.marketCap;
    setText('priceUsd', p ? '$' + num(p.usd, 4) : '–');
    setText('priceBtc', p ? num(p.btc, 8) + ' BTC' : '–');
    setText('priceKmd', p && p.kmd ? num(p.kmd, 4) + ' KMD' : '–');
    setText('mcapUsd', m ? '$' + num(m.usd) : '–');
    setText('mcapBtc', m ? num(m.btc, 1) + ' BTC' : '–');
    setText('mcapKmd', m && m.kmd ? num(m.kmd) + ' KMD' : '–');

    setText('shieldedPct', pct(d.shieldedPercent, 2));
    var bar = $('poolBar'), legend = $('poolLegend'); bar.textContent = ''; legend.textContent = '';
    POOLS.forEach(function (pool) {
      var v = d.pools[pool[0]] || 0, share = 100 * v / d.supply;
      var seg = el('div'); seg.style.flex = String(Math.max(share, .4)); seg.style.background = pool[2]; seg.title = pool[1] + ': ' + arrr(v);
      bar.append(seg);
      var item = el('span'), sw = el('i'); sw.style.background = pool[2];
      item.append(sw, pool[1] + ' ' + compact(v) + ' (' + pct(share) + ')'); legend.append(item);
    });
    var au = $('anonsetUnspent'); au.textContent = '';
    if (d.anonsetUnspent != null) au.textContent = num(d.anonsetUnspent) + ' notes';
    else au.append(el('span', 'sub', 'after history scan (' + d.backfill.percent + '%)'));
    setText('anonset', num(d.anonsetTotal) + ' notes');
    setText('anonSapling', num(d.anonset.sapling));
    setText('anonIronwood', num(d.anonset.ironwood));
    setText('anonSprout', num(d.anonset.sprout));
    var vel = $('velocity'); vel.textContent = '';
    if (d.anonsetVelocity != null) vel.textContent = d.anonsetVelocity.toFixed(2) + ' s/note'; else vel.append(el('span', 'sub', 'after history scan'));

    if (d.ironwood) {
      setText('iwValue', num(d.ironwood.value));
      setText('iwShare', pct(d.ironwood.shareOfShielded, 2));
      setText('iwNotes', num(d.ironwood.notes));
      var since = $('iwSince'); since.textContent = '';
      since.append(blockLink(d.ironwood.activationHeight, 'block ' + num(d.ironwood.activationHeight)));
      if (d.ironwood.activationTime) since.append(el('div', 'sub', fmtDay(d.ironwood.activationTime * 1000, true) + ' · ' + ago(d.ironwood.activationTime)));
    }

    var tb = $('activityBody'); tb.textContent = '';
    ROWS.forEach(function (r) {
      var tr = el('tr'); if (r[3]) tr.className = 'key';
      var td = el('td', null, r[1]); td.append(tipIcon(r[2])); tr.append(td);
      WINDOWS.forEach(function (w) { tr.append(el('td', null, num(d.activity[w][r[0]]))); });
      tb.append(tr);
    });
    ['badgeMain', 'badgeShort'].forEach(function (id, k) { var b = $(id); if (b) b.src = '/stats/' + (k ? 'badge-anonset.svg' : 'badge.svg') + '?t=' + d.updated; });
    setText('backfillNote', d.backfill.complete ? '' : 'Scanning chain history: ' + d.backfill.percent + '% done. The Total column is still filling in.');
  }

  function tickCountdown() {
    if (!S || !S.emission || !S.emission.secondsToHalving) return;
    var left = S.emission.secondsToHalving - (Date.now() / 1000 - S.updated);
    if (left < 0) left = 0;
    var dd = Math.floor(left / 86400), hh = Math.floor(left % 86400 / 3600), mm = Math.floor(left % 3600 / 60), ss = Math.floor(left % 60);
    var txt = 'in ' + dd + 'd ' + String(hh).padStart(2, '0') + 'h ' + String(mm).padStart(2, '0') + 'm ' + String(ss).padStart(2, '0') + 's';
    document.querySelectorAll('.countdown').forEach(function (c) { c.textContent = txt; });
  }
  setInterval(tickCountdown, 1000);

  function tipIcon(text) { var i = el('i', 'tip'); i.tabIndex = 0; i.setAttribute('data-tip', text); return i; }

  function renderHistory() {
    if (!D || !D.x.length) return;
    var last = function (a, n) { return a.slice(-n); };
    spark($('sAnonset'), last(D.anonset, 90), C.c1);
    spark($('sShielded'), last(D.shieldedShare, 90), C.c1);
    spark($('sZz'), last(D.zz, 31).slice(0, -1), C.c1);          // full days only
    var px = last(D.priceUsd, 90).filter(function (v) { return v != null; });
    spark($('sPrice'), px, C.c1);
    if (px.length > 1 && S) {
      var prev = D.priceUsd[D.priceUsd.length - 2], cur = S.prices && S.prices.usd;
      if (prev && cur) { var ch = 100 * (cur / prev - 1), sub = $('kPriceSub'); sub.textContent = 'USD · ';
        sub.append(el('span', ch >= 0 ? 'up' : 'down', (ch >= 0 ? '+' : '') + ch.toFixed(2) + '% 24h')); }
    }
    var iw = H.ironwood;
    if (iw && iw.hour.length) {
      chart($('iwChart'), {x: iw.hour.map(function (t) { return t * 1000; }), hourly: true, height: 230,
        series: [{name: 'ARRR in Ironwood', key: 'pool', values: iw.pool, color: C.c3, type: 'area', fmt: function (v) { return arrr(v); }}],
        });
    }
    heatmap($('heatmap'), H.heatmap.zz, 'private transactions');
    records($('records'));
    $('recordsNote').textContent = H.coverage.complete ? '' : 'Based on history scanned so far; the full history is still being scanned.';
  }

  // ---------- sparkline ----------
  function spark(svg, values, color) {
    if (!svg) return;
    var v = values.filter(function (x) { return x != null; });
    svg.textContent = '';
    if (v.length < 2) return;
    var w = svg.clientWidth || 200, h = svg.clientHeight || 40, pad = 4;
    var min = Math.min.apply(null, v), max = Math.max.apply(null, v), rng = max - min || 1;
    var pts = v.map(function (y, i) { return [i / (v.length - 1) * w, pad + (h - 2 * pad) * (1 - (y - min) / rng)]; });
    var line = pts.map(function (p, i) { return (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join('');
    svg.setAttribute('viewBox', '0 0 ' + w + ' ' + h); svg.setAttribute('preserveAspectRatio', 'none');
    svg.innerHTML = '<path d="' + line + 'L' + w + ' ' + h + 'L0 ' + h + 'Z" fill="' + color + '" opacity=".10"/>' +
      '<path d="' + line + '" fill="none" stroke="' + color + '" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round" vector-effect="non-scaling-stroke"/>';
  }

  // ---------- charts ----------
  function niceStep(range, ticks) {
    var raw = range / ticks, mag = Math.pow(10, Math.floor(Math.log10(raw))), f = raw / mag;
    return (f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10) * mag;
  }
  function bucketize(cfg, maxPts) {
    var n = cfg.x.length, g = Math.max(1, Math.ceil(n / maxPts));
    if (g === 1 || cfg.timeX) return {x: cfg.x, series: cfg.series, g: 1, partialLast: cfg.partialLast};
    var xs = [], series = cfg.series.map(function (s) { return Object.assign({}, s, {values: []}); });
    for (var i = 0; i < n; i += g) {
      xs.push(cfg.x[i]);
      cfg.series.forEach(function (s, k) {
        var part = s.values.slice(i, i + g).filter(function (v) { return v != null; }), v = null;
        // grouped counts become the average per day (or hour), so "per day" stays true at every zoom level
        if (part.length) v = s.agg === 'sum' || s.agg === 'mean' ? part.reduce(function (a, b) { return a + b; }, 0) / part.length : part[part.length - 1];
        series[k].values.push(v);
      });
    }
    return {x: xs, series: series, g: g, partialLast: cfg.partialLast};
  }

  function axisCompact(v, unit, dec) {
    if (v === 0) return '0';
    var suf = {1e12: 'T', 1e9: 'B', 1e6: 'M', 1e3: 'K', 1: ''}[unit];
    return (v / unit).toFixed(dec) + suf;
  }

  function chart(host, cfg) {
    host._cfg = cfg;
    if (!host._ro && window.ResizeObserver) {
      var lastW = 0;
      host._ro = new ResizeObserver(function () { var w = host.clientWidth; if (w && Math.abs(w - lastW) > 4) { lastW = w; drawChart(host); } });
      host._ro.observe(host);
    }
    drawChart(host);
  }

  function drawChart(host) {
    var cfg = host._cfg, W = host.clientWidth;
    if (!W) return;
    host.classList.add('chart');
    var isBar = cfg.series.some(function (s) { return s.type === 'bar'; });
    var b = bucketize(cfg, isBar ? Math.max(20, Math.floor(W / 9)) : Math.max(60, Math.floor(W / 2)));
    var xs = b.x, series = b.series, n = xs.length, Hh = cfg.height || 220;
    host.textContent = '';
    if (n < 2) { host.innerHTML = '<svg height="' + Hh + '"><text class="empty" x="50%" y="50%" text-anchor="middle">Collecting data…</text></svg>'; return; }

    // y domain
    var vals = [];
    if (cfg.stacked) { for (var i = 0; i < n; i++) { var s = 0; series.forEach(function (se) { s += se.values[i] || 0; }); vals.push(s); } }
    else series.forEach(function (se) { se.values.forEach(function (v) { if (v != null) vals.push(v); }); });
    if (!vals.length) return;
    var vmax = Math.max.apply(null, vals), vmin = Math.min.apply(null, vals);
    if (cfg.ref) { vmax = Math.max(vmax, cfg.ref.y); vmin = Math.min(vmin, cfg.ref.y); }
    var zero = isBar || cfg.stacked || cfg.zero || vmin <= 0 || vmin < vmax * 0.35;
    var lo = zero ? Math.min(0, vmin) : vmin - (vmax - vmin) * 0.12, hi = vmax === lo ? lo + 1 : vmax;
    var step = niceStep(hi - lo, Hh < 180 ? 3 : 4);
    lo = Math.floor(lo / step) * step; hi = Math.ceil(hi / step) * step;
    var ticks = []; for (var t = lo; t <= hi + step / 2; t += step) ticks.push(t);
    var unit = [1e12, 1e9, 1e6, 1e3].filter(function (u) { return Math.max(Math.abs(hi), Math.abs(lo)) >= u; })[0] || 1;
    var dec = Math.max(0, -Math.floor(Math.log10(step / unit) + 1e-9));
    var dec1 = Math.max(0, -Math.floor(Math.log10(step) + 1e-9));
    var yFmt = cfg.yFmt ? function (v) { return cfg.yFmt(v, dec1); } : function (v) { return axisCompact(v, unit, dec); };
    var left = 10 + Math.max.apply(null, ticks.map(function (t) { return yFmt(t).length; })) * 6.4, right = 12, top = 10, bottom = 24;
    var pw = W - left - right, ph = Hh - top - bottom;
    var band = pw / n, X = function (i) { return left + band * (i + .5); };
    if (cfg.timeX) { var x0 = xs[0], x1 = xs[n - 1]; X = function (i) { return left + pw * (xs[i] - x0) / (x1 - x0); }; }
    var Y = function (v) { return top + ph * (1 - (v - lo) / (hi - lo)); };

    var NS = 'http://www.w3.org/2000/svg', svg = document.createElementNS(NS, 'svg');
    svg.setAttribute('height', Hh); svg.setAttribute('viewBox', '0 0 ' + W + ' ' + Hh);
    svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', cfg.series.map(function (s) { return s.name; }).join(', '));
    var html = '<g class="axis">';
    ticks.forEach(function (t) {
      var y = Y(t).toFixed(1);
      html += '<line class="' + (t === 0 ? 'baseline' : 'gridline') + '" x1="' + left + '" x2="' + (W - right) + '" y1="' + y + '" y2="' + y + '"/>';
      html += '<text x="' + (left - 8) + '" y="' + y + '" dy="4" text-anchor="end">' + yFmt(t) + '</text>';
    });
    var span = xs[n - 1] - xs[0], nx = Math.max(2, Math.min(6, Math.floor(pw / 90)));
    var tickIdx = [];
    if (cfg.labels) { for (var q = 0; q < n; q += cfg.tickEvery || 1) tickIdx.push(q); }
    else if (cfg.timeX) {
      var y0 = new Date(xs[0]).getUTCFullYear(), y1 = new Date(xs[n - 1]).getUTCFullYear(), every = Math.max(1, Math.ceil((y1 - y0) / Math.max(2, Math.floor(pw / 70))));
      for (var yr = Math.ceil(y0 / every) * every; yr <= y1; yr += every) {
        var target = Date.UTC(yr, 0, 1), best = 0;
        xs.forEach(function (v, j) { if (Math.abs(v - target) < Math.abs(xs[best] - target)) best = j; });
        if (Math.abs(xs[best] - target) < 200 * 864e5) tickIdx.push(best);
      }
    }
    else for (var q2 = 0; q2 < nx; q2++) tickIdx.push(Math.round(q2 * (n - 1) / (nx - 1)));
    tickIdx.forEach(function (idx, k) {
      var ms = xs[idx], d = new Date(ms);
      var lab = cfg.labels ? cfg.labels[idx] : cfg.timeX ? String(d.getUTCFullYear()) : cfg.hourly ? (k === 0 || d.getUTCHours() < 2 ? fmtDay(ms) + ' ' : '') + String(d.getUTCHours()).padStart(2, '0') + ':00'
        : span > 400 * 864e5 ? MON[d.getUTCMonth()] + ' ’' + String(d.getUTCFullYear()).slice(2) : fmtDay(ms);
      var anchor = cfg.labels ? 'middle' : k === 0 ? 'start' : k === tickIdx.length - 1 ? 'end' : 'middle';
      html += '<text x="' + X(idx).toFixed(1) + '" y="' + (Hh - 6) + '" text-anchor="' + anchor + '">' + lab + '</text>';
    });
    html += '</g>';
    if (cfg.ref) {
      var ry = Y(cfg.ref.y).toFixed(1);
      html += '<line class="ref" x1="' + left + '" x2="' + (W - right) + '" y1="' + ry + '" y2="' + ry + '"/><text class="ref-label" x="' + (left + 6) + '" y="' + ry + '" dy="-6" text-anchor="start">' + cfg.ref.label + '</text>';
    }
    // marks
    var bw = Math.max(1, Math.min(24, band * .72, band - 2)), r = bw >= 8 ? 4 : bw >= 4 ? 2 : 0;
    var base = new Array(n).fill(0);
    series.forEach(function (se, si) {
      if (se.type === 'bar') {
        se.values.forEach(function (v, i) {
          if (!v) return;
          var y0 = cfg.stacked ? base[i] : 0, y1 = y0 + v;
          var top_ = Y(y1), bot = Y(y0) - (cfg.stacked && y0 > 0 ? 2 : 0), x = X(i) - bw / 2, h = Math.max(0, bot - top_);
          var isTop = !cfg.stacked || si === series.length - 1 || series.slice(si + 1).every(function (s2) { return !s2.values[i]; });
          var rr = isTop ? Math.min(r, h, bw / 2) : 0;
          var op = b.partialLast && i === n - 1 ? .45 : 1;
          html += '<path data-i="' + i + '" fill="' + se.color + '" opacity="' + op + '" d="M' + x.toFixed(1) + ' ' + bot.toFixed(1) + 'V' + (top_ + rr).toFixed(1) +
            (rr ? 'q0 -' + rr + ' ' + rr + ' -' + rr + 'h' + (bw - 2 * rr).toFixed(1) + 'q' + rr + ' 0 ' + rr + ' ' + rr : 'h' + bw.toFixed(1)) + 'V' + bot.toFixed(1) + 'Z"/>';
          if (cfg.stacked) base[i] = y1;
        });
      } else {
        var d = '', area = '', started = false, lastPt = null;
        se.values.forEach(function (v, i) {
          if (v == null) { started = false; return; }
          var p = X(i).toFixed(1) + ' ' + Y(v).toFixed(1);
          d += (started ? 'L' : 'M') + p; started = true; lastPt = [X(i), Y(v)];
        });
        if (se.type === 'area') {
          var idxs = se.values.map(function (v, i) { return v == null ? -1 : i; }).filter(function (i) { return i >= 0; });
          if (idxs.length) area = d + 'L' + X(idxs[idxs.length - 1]).toFixed(1) + ' ' + Y(Math.max(lo, 0)).toFixed(1) + 'L' + X(idxs[0]).toFixed(1) + ' ' + Y(Math.max(lo, 0)).toFixed(1) + 'Z';
          html += '<path d="' + area + '" fill="' + se.color + '" opacity=".12"/>';
        }
        html += '<path d="' + d + '" fill="none" stroke="' + se.color + '" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"' + (se.dash ? ' stroke-dasharray="5 5" opacity=".75"' : '') + '/>';
        if (lastPt) html += '<circle cx="' + lastPt[0].toFixed(1) + '" cy="' + lastPt[1].toFixed(1) + '" r="4" fill="' + se.color + '" stroke="' + C.surface + '" stroke-width="2"/>';
      }
    });
    html += '<line class="cross" x1="0" x2="0" y1="' + top + '" y2="' + (top + ph) + '" visibility="hidden"/><g class="hover-dots"></g>';
    html += '<rect class="hit" x="' + left + '" y="0" width="' + pw + '" height="' + Hh + '" fill="transparent"/>';
    svg.innerHTML = html;
    host.append(svg);

    if (series.length > 1) {
      var lg = el('div', 'chart-legend');
      series.forEach(function (se) { var it = el('span'), k = el('i', se.type === 'bar' ? '' : 'line-key'); k.style.background = se.color;
        k.style.cssText += ';display:inline-block;width:' + (se.type === 'bar' ? '9px;height:9px;border-radius:2px' : '14px;height:2px;border-radius:1px;vertical-align:3px') + ';margin-right:6px';
        it.append(k, se.name); lg.append(it); });
      host.append(lg);
    }
    if (cfg.table !== false) host.append(dataTable(xs, series, cfg, b.g));

    // hover / scrub
    var cross = svg.querySelector('.cross'), dots = svg.querySelector('.hover-dots'), hit = svg.querySelector('.hit');
    function show(clientX, clientY) {
      var rect = svg.getBoundingClientRect(), sx = (clientX - rect.left) * (W / rect.width);
      var i = Math.max(0, Math.min(n - 1, Math.round((sx - left) / band - .5)));
      if (cfg.timeX) { var tx_ = xs[0] + (sx - left) / pw * (xs[n - 1] - xs[0]); i = 0; xs.forEach(function (v, j) { if (Math.abs(v - tx_) < Math.abs(xs[i] - tx_)) i = j; }); }
      cross.setAttribute('x1', X(i)); cross.setAttribute('x2', X(i)); cross.setAttribute('visibility', 'visible');
      dots.innerHTML = '';
      series.forEach(function (se) { if (se.type !== 'bar' && se.values[i] != null)
        dots.innerHTML += '<circle cx="' + X(i) + '" cy="' + Y(se.values[i]) + '" r="4.5" fill="' + se.color + '" stroke="' + C.surface + '" stroke-width="2"/>'; });
      svg.querySelectorAll('path[data-i]').forEach(function (p) { p.style.filter = +p.getAttribute('data-i') === i ? 'brightness(1.25)' : ''; });
      var tip = $('charttip'); tip.textContent = '';
      var head = cfg.labels ? (cfg.longLabels || cfg.labels)[i] : cfg.timeX ? fmtDay(xs[i], true) : cfg.hourly ? fmtTime(xs[i]) : b.g > 1 ? fmtDay(xs[i], true) + ' – ' + fmtDay(xs[Math.min(i + 1, n - 1)] - (i + 1 < n ? 864e5 : 0), true) : fmtDay(xs[i], true);
      if (b.partialLast && i === n - 1 && !cfg.labels) head += ' (so far)';
      if (b.g > 1 && series.some(function (se) { return se.agg === 'sum'; })) head += ' · average per ' + (cfg.hourly ? 'hour' : 'day');
      tip.append(el('div', 't-head', head));
      series.slice().reverse().forEach(function (se) {
        var row = el('div', 't-row'), key = el('i', 't-key'); key.style.background = se.color;
        row.append(key, el('b', null, (se.fmt || function (v) { return num(v, 2); })(se.values[i])), el('span', null, se.name)); tip.append(row);
      });
      tip.hidden = false;
      var tw = tip.offsetWidth, th = tip.offsetHeight, tx = clientX + 14, ty = clientY - th - 12;
      if (tx + tw > window.innerWidth - 8) tx = clientX - tw - 14;
      if (ty < 8) ty = clientY + 18;
      tip.style.left = Math.max(8, tx) + 'px'; tip.style.top = ty + 'px';
    }
    function hide() { cross.setAttribute('visibility', 'hidden'); dots.innerHTML = ''; $('charttip').hidden = true;
      svg.querySelectorAll('path[data-i]').forEach(function (p) { p.style.filter = ''; }); }
    hit.addEventListener('pointermove', function (e) { show(e.clientX, e.clientY); });
    hit.addEventListener('pointerdown', function (e) { e.stopPropagation(); show(e.clientX, e.clientY); });
    hit.addEventListener('click', function (e) { e.stopPropagation(); });
    hit.addEventListener('pointerleave', function (e) { if (e.pointerType === 'mouse') hide(); });
    host._hide = hide;
  }

  function dataTable(xs, series, cfg, g) {
    var det = el('details', 'data-table'), sum = el('summary', null, 'Show data table');
    det.append(sum);
    det.addEventListener('click', function (e) { e.stopPropagation(); });
    det.addEventListener('toggle', function () {
      if (!det.open || det._built) return; det._built = true;
      var wrap = el('div', 'table-wrap'), t = el('table'), hr = el('tr');
      hr.append(el('th', null, cfg.labels ? '' : cfg.hourly ? 'Hour (UTC)' : g > 1 ? 'Period from' : 'Day'));
      series.forEach(function (s) { hr.append(el('th', null, s.name)); });
      var th = el('thead'); th.append(hr); t.append(th);
      var tb = el('tbody');
      for (var i = xs.length - 1; i >= 0; i--) {
        var tr = el('tr'); tr.append(el('td', null, cfg.labels ? (cfg.longLabels || cfg.labels)[i] : cfg.hourly ? fmtTime(xs[i]) : fmtDay(xs[i], true)));
        series.forEach(function (s) { tr.append(el('td', null, (s.fmt || function (v) { return num(v, 2); })(s.values[i]))); });
        tb.append(tr);
      }
      t.append(tb); wrap.append(t); det.append(wrap);
    });
    return det;
  }

  // ---------- heatmap ----------
  function heatmap(host, grid, what) {
    host.textContent = '';
    var vals = []; grid.forEach(function (r) { r.forEach(function (v) { if (v > 0) vals.push(v); }); });
    vals.sort(function (a, b) { return a - b; });
    var q = [.2, .4, .6, .8].map(function (p) { return vals[Math.floor(p * (vals.length - 1))] || 0; });
    var bin = function (v) { if (!v) return -1; var b = 0; while (b < 4 && v > q[b]) b++; return b; };
    host.append(el('span'));
    for (var h = 0; h < 24; h++) host.append(el('span', 'hh', h % 6 === 0 ? String(h).padStart(2, '0') : ''));
    var cells = [];
    grid.forEach(function (row, d) {
      host.insertBefore(el('span', 'hl', DAYS[d]), null);
      row.forEach(function (v, h) {
        var c = el('span', 'cell'), b = bin(v);
        if (b >= 0) c.style.background = HEAT[b];
        c.tabIndex = -1; c._label = DAYS[d] + ' ' + String(h).padStart(2, '0') + ':00–' + String((h + 1) % 24).padStart(2, '0') + ':00 UTC';
        c._value = v; cells.push(c);
        host.append(c);
      });
    });
    // hours row goes last on a 25-column grid: move it to the bottom for readability
    var head = Array.prototype.slice.call(host.querySelectorAll('.hh')); head.unshift(host.firstChild);
    head.forEach(function (n) { host.append(n); });
    var lg = el('div', 'heat-legend'); lg.append('fewer');
    HEAT.forEach(function (c) { var i = el('i'); i.style.background = c; lg.append(i); }); lg.append('more ' + what);
    host.parentNode.querySelectorAll('.heat-legend').forEach(function (n) { n.remove(); });
    host.after(lg);
    function show(c, x, y) {
      cells.forEach(function (o) { o.classList.toggle('on', o === c); });
      var tip = $('charttip'); tip.textContent = '';
      tip.append(el('div', 't-head', c._label)); var row = el('div', 't-row'); row.append(el('b', null, num(c._value)), el('span', null, what)); tip.append(row);
      tip.hidden = false; var tw = tip.offsetWidth, tx = x + 12, ty = y - tip.offsetHeight - 10;
      if (tx + tw > innerWidth - 8) tx = x - tw - 12; if (ty < 8) ty = y + 16;
      tip.style.left = Math.max(8, tx) + 'px'; tip.style.top = ty + 'px';
    }
    host.addEventListener('pointermove', function (e) { if (e.target._label) show(e.target, e.clientX, e.clientY); });
    host.addEventListener('pointerdown', function (e) { if (e.target._label) { e.stopPropagation(); show(e.target, e.clientX, e.clientY); } });
    host.addEventListener('click', function (e) { if (e.target._label) e.stopPropagation(); });
    host.addEventListener('pointerleave', function (e) { if (e.pointerType === 'mouse') { $('charttip').hidden = true; cells.forEach(function (o) { o.classList.remove('on'); }); } });
  }

  // ---------- records ----------
  function records(ul) {
    ul.textContent = '';
    var R = H.records;
    function item(label, value, sub) {
      var li = el('li'), v = el('span', 'r-value'); li.append(el('span', 'r-label', label));
      if (value instanceof Node) v.append(value); else v.textContent = value;
      if (sub) { var s = el('small'); if (sub instanceof Node) s.append(sub); else s.textContent = sub; v.append(s); }
      li.append(v); ul.append(li);
    }
    if (R.busiestDayZz) item('Busiest day (private tx)', num(R.busiestDayZz.value), fmtDay(Date.parse(R.busiestDayZz.day), true));
    if (R.busiestDayNotes) item('Most new notes in a day', num(R.busiestDayNotes.value), fmtDay(Date.parse(R.busiestDayNotes.day), true));
    if (R.busiestBlockZz.height) item('Most private tx in one block', num(R.busiestBlockZz.value), blockLink(R.busiestBlockZz.height, 'block ' + num(R.busiestBlockZz.height)));
    if (R.biggestBlock.height) item('Largest block', num(R.biggestBlock.value / 1024, 0) + ' KB', blockLink(R.biggestBlock.height, 'block ' + num(R.biggestBlock.height)));
    if (R.longestGap.height) item('Longest wait between blocks', Math.floor(R.longestGap.value / 60) + ' min ' + (R.longestGap.value % 60) + ' s', blockLink(R.longestGap.height, 'before block ' + num(R.longestGap.height)));
    (R.anonsetMilestones || []).slice().reverse().forEach(function (m) { item('Anonset passed ' + compact(m.value) + ' notes', fmtDay(m.time * 1000, true), blockLink(m.height, 'block ' + num(m.height))); });
    (R.shareMilestones || []).slice().reverse().forEach(function (m) { item('Shielded share passed ' + m.value + '%', fmtDay(m.time * 1000, true), blockLink(m.height, 'block ' + num(m.height))); });
    if (S && S.ironwood) item('Ironwood activated', fmtDay(S.ironwood.activationTime * 1000, true), blockLink(S.ironwood.activationHeight, 'block ' + num(S.ironwood.activationHeight)));
  }

  // ---------- focus view: per-card charts ----------
  function rangeSlice(days) {
    if (!D) return null;
    var n = D.x.length, from = days ? Math.max(0, n - days) : 0, out = {};
    Object.keys(D).forEach(function (k) { out[k] = Array.isArray(D[k]) ? D[k].slice(from) : D[k]; });
    return out;
  }
  var RANGES = [['30d', 30], ['90d', 90], ['1y', 365], ['all', 0]];
  var dailyFmt = {
    count: function (v) { return num(v); }, arrr: function (v) { return arrr(v); }, pct: function (v) { return v == null ? '–' : v.toFixed(3) + '%'; },
    secs: function (v) { return v == null ? '–' : v.toFixed(1) + ' s'; }, usd: usd, hash: hashrate, diff: function (v) { return num(v); },
    mcap: function (v) { return v == null ? '–' : '$' + num(v); }, btc: function (v) { return v == null ? '–' : num(v, 8) + ' BTC'; }
  };
  var FOCUS_CHARTS = {
    chain: [
      {title: 'Average block time', sub: 'Daily average; target 60 s', ref: {y: 60, label: 'target 60 s'}, yFmt: function (v, d) { return v.toFixed(d) + 's'; },
        series: [{name: 'Avg block time', key: 'blockTime', color: C.c1, type: 'line', agg: 'mean', fmt: dailyFmt.secs}]},
      {title: 'Slow blocks', sub: 'Blocks that took longer than 2 minutes, per day', series: [{name: 'Slow blocks', key: 'slowBlocks', color: C.c2, type: 'bar', agg: 'sum', fmt: dailyFmt.count}]}
    ],
    supply: [
      {title: 'Shielded share of circulating ARRR', sub: 'Sapling + Ironwood vs transparent', yFmt: function (v, d) { return v.toFixed(d) + '%'; },
        series: [{name: 'Shielded share', key: 'shieldedShare', color: C.c1, type: 'line', agg: 'last', fmt: dailyFmt.pct}]},
      {multiples: true, items: [
        {title: 'Sapling pool', series: [{name: 'ARRR in Sapling', key: 'poolSapling', color: C.c1, type: 'line', agg: 'last', fmt: dailyFmt.arrr}]},
        {title: 'Transparent', series: [{name: 'Transparent ARRR', key: 'poolTransparent', color: C.c2, type: 'line', agg: 'last', fmt: dailyFmt.arrr}]},
        {title: 'Ironwood pool', series: [{name: 'ARRR in Ironwood', key: 'poolIronwood', color: C.c3, type: 'area', agg: 'last', fmt: dailyFmt.arrr}]}]}
    ],
    network: [
      {title: 'Estimated hashrate', sub: 'Daily average, from difficulty and block time', 
        series: [{name: 'Hashrate', key: 'hashrate', color: C.c1, type: 'area', agg: 'mean', fmt: dailyFmt.hash}]},
      {title: 'Difficulty', sub: 'Daily average', series: [{name: 'Difficulty', key: 'difficulty', color: C.c2, type: 'line', agg: 'mean', fmt: dailyFmt.diff}]},
      {title: 'Nodes seen per day', sub: 'Distinct peers of this explorer\'s node; recorded since Oct 2026', series: [{name: 'Nodes', key: 'nodes', color: C.c3, type: 'line', agg: 'mean', fmt: dailyFmt.count}]}
    ],
    price: [
      {title: 'ARRR price', sub: 'USD, daily (CoinGecko)', yFmt: function (v, d) { return '$' + v.toFixed(d); },
        series: [{name: 'Price USD', key: 'priceUsd', color: C.c1, type: 'area', agg: 'mean', fmt: dailyFmt.usd}]},
      {title: 'Market cap', sub: 'USD',  series: [{name: 'Market cap', key: 'mcapUsd', color: C.c2, type: 'line', agg: 'mean', fmt: dailyFmt.mcap}]},
      {title: 'ARRR in BTC', yFmt: function (v, d) { return (v * 1e8).toFixed(Math.max(0, d - 8)) + ' sat'; }, series: [{name: 'Price BTC', key: 'priceBtc', color: C.c4, type: 'line', agg: 'mean', fmt: dailyFmt.btc}]}
    ],
    privacy: [
      {title: 'Anonset growth', sub: 'All notes (from the note trees) and unspent notes (old dexstats definition)',
        series: [{name: 'All notes', key: 'anonset', color: C.c1, type: 'line', agg: 'last', fmt: dailyFmt.count},
                 {name: 'Unspent notes', key: 'anonsetUnspent', color: C.c2, type: 'line', agg: 'last', fmt: dailyFmt.count}]},
      {title: 'New notes per day', series: [{name: 'New notes', key: 'newNotes', color: C.c1, type: 'bar', agg: 'sum', fmt: dailyFmt.count}]}
    ],
    activity: [
      {title: 'Transactions by type', sub: 'Per day, excluding the one coinbase per block', stacked: true,
        series: [{name: 'z→z shielded', key: 'zz', color: C.c1, type: 'bar', agg: 'sum', fmt: dailyFmt.count},
                 {name: 'Shielding t→z', key: 'shielding', color: C.c2, type: 'bar', agg: 'sum', fmt: dailyFmt.count},
                 {name: 'Deshielding z→t', key: 'deshielding', color: C.c4, type: 'bar', agg: 'sum', fmt: dailyFmt.count},
                 {name: 'Transparent (dPoW)', key: 'transparent', color: C.c5, type: 'bar', agg: 'sum', fmt: dailyFmt.count}]},
      {title: 'Fully shielded transactions', sub: 'z→z per day', series: [{name: 'z→z shielded', key: 'zz', color: C.c1, type: 'bar', agg: 'sum', fmt: dailyFmt.count}]}
    ]
  };

  function addChart(parent, spec, data) {
    var blk = el('div', 'chart-block');
    if (spec.title) blk.append(el('h3', null, spec.title));
    if (spec.sub) blk.append(el('div', 'c-sub', spec.sub));
    var host = el('div'); host.setAttribute('data-noswipe', ''); blk.append(host); parent.append(blk);
    chart(host, {x: data.x, partialLast: spec.series.some(function (s) { return s.agg === 'sum'; }), stacked: spec.stacked, ref: spec.ref,
      height: spec.height || (innerWidth < 700 ? 190 : 230), yFmt: spec.yFmt, hourly: data.hourly,
      series: spec.series.map(function (s) { return Object.assign({}, s, {values: data[s.key] || []}); })});
  }

  function addCategoryChart(parent, title, labels, longLabels, values, what, every) {
    var blk = el('div', 'chart-block'); blk.append(el('h3', null, title));
    var host = el('div'); host.setAttribute('data-noswipe', ''); blk.append(host); parent.append(blk);
    chart(host, {x: values.map(function (v, i) { return i; }), labels: labels, longLabels: longLabels, tickEvery: every, height: innerWidth < 700 ? 170 : 200,
      series: [{name: what, values: values, color: C.c1, type: 'bar', agg: 'sum', fmt: function (v) { return num(v); }}]});
  }

  function focusExtras(id, body, animate) {
    if (id === 'ironwood' && H && H.ironwood && H.ironwood.hour.length) {
      var iw = H.ironwood, data = {x: iw.hour.map(function (t) { return t * 1000; }), hourly: true, pool: iw.pool, notes: iw.notes, actions: iw.actions};
      addChart(body, {title: 'ARRR in Ironwood', sub: 'Hourly since activation', series: [{name: 'ARRR in Ironwood', key: 'pool', color: C.c3, type: 'area', agg: 'last', fmt: dailyFmt.arrr}]}, data);
      addChart(body, {title: 'Ironwood notes', series: [{name: 'Notes', key: 'notes', color: C.c3, type: 'line', agg: 'last', fmt: dailyFmt.count}]}, data);
      addChart(body, {title: 'Ironwood actions per hour', series: [{name: 'Actions', key: 'actions', color: C.c3, type: 'bar', agg: 'sum', fmt: dailyFmt.count}]}, data);
    }
    if (id === 'chain' && S && S.emission) emissionContent(body);
    if (id === 'upgrade' && S && S.upgrade) upgradeContent(body);
    if (FOCUS_CHARTS[id] && D) {
      var bar = el('div'), rg = el('div', 'ranges');
      RANGES.forEach(function (r) {
        var bt = el('button', null, r[0] === 'all' ? 'All' : r[0].toUpperCase()); bt.setAttribute('aria-pressed', String(focusRange === r[0]));
        bt.addEventListener('click', function (e) { e.stopPropagation(); focusRange = r[0]; renderFocus(false); }); rg.append(bt);
      });
      bar.append(rg);
      if (!H.coverage.complete) bar.append(el('span', 'coverage', 'History scan in progress: charts start ' + fmtDay(D.x[0], true)));
      body.append(bar);
      var data = rangeSlice(RANGES.filter(function (r) { return r[0] === focusRange; })[0][1]);
      FOCUS_CHARTS[id].forEach(function (spec) {
        if (spec.multiples) { var m = el('div', 'multiples'); body.append(m); spec.items.forEach(function (it) { addChart(m, Object.assign({height: 170}, it), data); }); }
        else addChart(body, spec, data);
      });
    }
    if (id === 'heatmap' && H) {
      var hm = el('div', 'heatmap'); hm.setAttribute('data-noswipe', '');
      var tg = el('div', 'ranges');
      [['zz', 'Private (z→z)'], ['tx', 'All non-coinbase']].forEach(function (o) {
        var bt = el('button', null, o[1]); bt.setAttribute('aria-pressed', String((body._heat || 'zz') === o[0]));
        bt.addEventListener('click', function (e) { e.stopPropagation(); heatKind = o[0]; renderFocus(false); }); tg.append(bt);
      });
      body.append(tg, el('div', 'c-sub', 'Transactions by weekday and hour, UTC, last 365 days. Tap a cell for its count.'));
      body.append(hm);
      tg.querySelectorAll('button').forEach(function (b, i) { b.setAttribute('aria-pressed', String((i === 0 ? 'zz' : 'tx') === heatKind)); });
      var grid = H.heatmap[heatKind], what = heatKind === 'zz' ? 'private transactions' : 'transactions';
      heatmap(hm, grid, what);
      var byHour = [], byDay = grid.map(function (r) { return r.reduce(function (a, b) { return a + b; }, 0); });
      for (var h = 0; h < 24; h++) byHour.push(grid.reduce(function (a, r) { return a + r[h]; }, 0));
      var total = byDay.reduce(function (a, b) { return a + b; }, 0), bh = byHour.indexOf(Math.max.apply(null, byHour)), bd = byDay.indexOf(Math.max.apply(null, byDay));
      var hl = function (h) { return String(h).padStart(2, '0') + ':00'; };
      var sum = el('p', 'fexplain'); sum.style.marginTop = '14px';
      sum.textContent = 'Busiest hour: ' + hl(bh) + '–' + hl((bh + 1) % 24) + ' UTC (' + pct(100 * byHour[bh] / total) + ' of ' + what + '). Busiest day: ' +
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][bd] + ' (' + pct(100 * byDay[bd] / total) + ').';
      body.append(sum);
      var hours = byHour.map(function (v, i) { return i; });
      addCategoryChart(body, 'By hour of day (UTC)', hours.map(hl), hours.map(function (i) { return hl(i) + '–' + hl((i + 1) % 24) + ' UTC'; }), byHour, what, 3);
      addCategoryChart(body, 'By weekday', DAYS, ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'], byDay, what, 1);
    }
    if (id === 'records' && H) { var ul = el('ul', 'records'); body.append(ul); records(ul); if (!H.coverage.complete) body.append(el('div', 'note', $('recordsNote').textContent)); }
    if (id === 'embed') embedContent(body);
  }
  var heatKind = 'zz';

  function emissionContent(body) {
    var e = S.emission;
    body.append(el('h3', null, 'Supply over time'), el('div', 'c-sub', 'Mined so far (solid) and projected from the reward schedule (dashed). Supply levels off near ' + compact(e.finalSupply, 2) + ' ARRR.'));
    var xs = [], mined = [], proj = [];
    if (D) {
      var step = Math.max(1, Math.floor(D.x.length / 150));
      for (var i = 0; i < D.x.length; i += step) {
        xs.push(D.x[i]); mined.push(D.poolTransparent[i] + D.poolSapling[i] + D.poolIronwood[i] + D.poolSprout[i]); proj.push(null);
      }
    }
    xs.push(S.updated * 1000); mined.push(S.supply); proj.push(S.supply);
    e.projected.forEach(function (p) { if (p.time * 1000 < Date.UTC(2046, 0, 1)) { xs.push(p.time * 1000); mined.push(null); proj.push(p.supply); } });
    var host = el('div'); host.setAttribute('data-noswipe', ''); body.append(host);
    chart(host, {x: xs, timeX: true, height: innerWidth < 700 ? 200 : 240, yFmt: function (v, d) { return (v / 1e6).toFixed(Math.max(1, d - 6)) + 'M'; },
      series: [{name: 'Mined', values: mined, color: C.c1, type: 'line', fmt: arrr}, {name: 'Projected', values: proj, color: C.c1, type: 'line', dash: true, fmt: arrr}]});
    body.append(el('h3', null, 'Reward schedule'), el('div', 'c-sub', 'The block reward halves every ' + num(e.halvingInterval) + ' blocks (about 9 months).'));
    var wrap = el('div', 'table-wrap'), t = el('table'), hr = el('tr');
    ['Halving', 'From block', 'Reward', 'Expected'].forEach(function (h, i) { var th = el('th', null, h); if (!i) th.style.textAlign = 'left'; hr.append(th); });
    var th_ = el('thead'); th_.append(hr); t.append(th_); var tb = el('tbody');
    e.eras.slice(0, 7).forEach(function (r, i) {
      var tr = el('tr'); if (i === 1) tr.className = 'key';
      tr.append(el('td', null, i === 0 ? 'Current' : i === 1 ? 'Next' : '#' + r.era), el('td', null, num(r.height)), el('td', null, r.reward + ' ARRR'),
        el('td', null, r.eta ? fmtDay(r.eta * 1000, true) : 'active'));
      tb.append(tr);
    });
    t.append(tb); wrap.append(t); body.append(wrap);
  }

  function upgradeContent(body) {
    var u = S.upgrade;
    body.append(el('h3', null, 'Versions of connected peers'), el('div', 'c-sub', 'Ironwood needs Dabloon ' + u.minVersion + ' or newer. Older nodes stopped at block 4,161,184.'));
    var wrap = el('div', 'table-wrap'), t = el('table'), hr = el('tr');
    ['Version', 'Peers', 'At chain tip', 'Status'].forEach(function (h, i) { var th = el('th', null, h); if (!i) th.style.textAlign = 'left'; hr.append(th); });
    var th_ = el('thead'); th_.append(hr); t.append(th_); var tb = el('tbody');
    u.versions.forEach(function (v) {
      var tr = el('tr'); if (!v.ready) tr.className = 'warn-row';
      var st = el('td'), dot = el('i', 'status-dot'); dot.style.background = v.ready ? C.c3 : C.c5;
      st.append(dot, v.ready ? 'Ironwood-ready' : 'Needs upgrade');
      tr.append(el('td', null, v.version), el('td', null, num(v.peers)), el('td', null, v.ready ? num(v.onTip) : '–'), st); tb.append(tr);
    });
    t.append(tb); wrap.append(t); body.append(wrap);
    body.append(el('div', 'note', '"At chain tip" counts peers that have reported a block within 10 of the tip; freshly connected peers may not have reported yet.'));
    var recorded = D && D.readyPercent ? D.readyPercent.filter(function (v) { return v != null; }).length : 0;
    if (recorded < 2) body.append(el('h3', null, 'Ironwood-ready peers over time'), el('div', 'c-sub', 'Recorded daily since Oct 4, 2026. The trend chart appears from the second day.'));
    else {
      var i0 = D.readyPercent.findIndex(function (v) { return v != null; });
      addChart(body, {title: 'Ironwood-ready peers', sub: 'Share of distinct peers per day; recorded since Oct 4, 2026', yFmt: function (v, d) { return v.toFixed(d) + '%'; },
        series: [{name: 'Ironwood-ready', key: 'readyPercent', color: C.c3, type: 'line', agg: 'last', fmt: function (v) { return v == null ? '–' : v.toFixed(1) + '%'; }}]},
        {x: D.x.slice(i0), readyPercent: D.readyPercent.slice(i0)});
    }
  }

  function snippet(code) {
    var w = el('div', 'snippet'), pre = el('pre', null, code), b = el('button', 'copy', 'Copy');
    b.addEventListener('click', function (e) {
      e.stopPropagation();
      (navigator.clipboard ? navigator.clipboard.writeText(code) : Promise.reject()).then(function () { b.textContent = 'Copied'; setTimeout(function () { b.textContent = 'Copy'; }, 1500); },
        function () { var r = document.createRange(); r.selectNodeContents(pre); var s = getSelection(); s.removeAllRanges(); s.addRange(r); b.textContent = 'Selected'; });
    });
    w.append(pre, b); return w;
  }
  function embedContent(body) {
    var origin = CANONICAL;   // dexstats hosts a copy; public links always use the official domain
    body.append(el('h3', null, 'Badges'), el('div', 'c-sub', 'SVG, updated every minute.'));
    var prev = el('div', 'embed-preview');
    // ?t= busts browser/CDN caches so the preview always matches the current figures
    ['badge.svg', 'badge-anonset.svg'].forEach(function (f) { var i = el('img'); i.src = '/stats/' + f + '?t=' + (S ? S.updated : Date.now()); i.height = 22; i.alt = '$ARRR anonset badge'; prev.append(i); });
    body.append(prev);
    body.append(el('div', 'c-sub', 'Markdown'), snippet('[![$ARRR anonset](' + origin + '/stats/badge.svg)](' + origin + '/stats/)'));
    body.append(el('div', 'c-sub', 'HTML'), snippet('<a href="' + origin + '/stats/"><img src="' + origin + '/stats/badge.svg" alt="$ARRR anonset" height="22"></a>'));
    body.append(el('h3', null, 'Open data'));
    var ul = el('ul', 'api');
    [['/stats/stats.json', 'Live figures: supply, pools, anonset, activity windows, network, prices. Every minute (prices every 10 minutes).'],
     ['/stats/history.json', 'Daily series since the history scan start, Ironwood hourly, heatmap and records. Hourly.'],
     ['/stats/badge.svg', 'Anonset and shielded share badge.']].forEach(function (a) {
      var li = el('li'), c = el('a'); c.href = a[0]; c.append(el('code', null, origin + a[0])); li.append(c, el('span', null, a[1])); ul.append(li);
    });
    body.append(ul);
  }

  // ---------- focus view ----------
  var focus = $('focus');
  function buildFocus(card, body) {
    var bar = card.querySelector('.bar'), legend = card.querySelector('.legend');
    card.querySelectorAll('.row').forEach(function (row, i) {
      var label = row.firstElementChild, value = row.lastElementChild, tip = label.querySelector('.tip');
      var fr = el('div', 'frow'), fl = el('div', 'fline'), v = el('span', 'fvalue ' + value.className);
      v.innerHTML = value.innerHTML;   // our own rendered values (numbers and links)
      fl.append(el('span', 'flabel', label.textContent), v); fr.append(fl);
      if (tip) fr.append(el('div', 'fexplain', tip.getAttribute('data-tip')));
      body.append(fr);
      if (i === 0 && bar) { body.append(bar.cloneNode(true), legend.cloneNode(true)); }
    });
    var intro = card.querySelector('.feature-intro, .card-intro');
    if (intro && card.id !== 'card-heatmap') body.insertBefore(el('p', 'fexplain', intro.textContent), body.firstChild);
    if (card.id === 'card-activity' && S) {
      ROWS.forEach(function (r) {
        var fr = el('div', 'frow' + (r[3] ? ' key' : '')); fr.append(el('div', 'flabel', r[1]), el('div', 'fexplain', r[2]));
        var g = el('div', 'fwins');
        WINDOWS.forEach(function (w) { var c = el('div'); c.append(el('b', null, num(S.activity[w][r[0]])), el('span', null, WIN_LABELS[w])); g.append(c); });
        fr.append(g); body.append(fr);
      });
    }
    if (card.id === 'card-ironwood') { var big = card.querySelector('.big'); if (big) body.insertBefore(big.cloneNode(true), body.children[1] || null); }
  }
  function renderFocus(animateFrom) {
    if (!focusId) return;
    var card = $('card-' + focusId), body = $('focusBody'), scroll = focus.querySelector('.panel').scrollTop;
    $('focusTitle').textContent = card.querySelector('h2').textContent;
    var dots = $('focusDots'); dots.textContent = '';
    ORDER.forEach(function (id) { dots.append(el('i', id === focusId ? 'on' : '')); });
    body.textContent = '';
    buildFocus(card, body);
    focusExtras(focusId, body);
    if (animateFrom === false) focus.querySelector('.panel').scrollTop = scroll;
  }
  function openFocus(id) {
    if (!$('card-' + id)) return closeFocus();
    var from = focusId ? ORDER.indexOf(focusId) : -1, to = ORDER.indexOf(id);
    focusId = id; hideTip(); $('charttip').hidden = true;
    focus.hidden = false; document.body.classList.add('focus-open');
    renderFocus(true);
    var body = $('focusBody'); body.classList.remove('from-left', 'from-right');
    if (from >= 0 && from !== to) { void body.offsetWidth; body.classList.add(to > from ? 'from-right' : 'from-left'); }
    focus.querySelector('.panel').scrollTop = 0;
    focus.querySelector('.close').focus({preventScroll: true});
  }
  function closeFocus() {
    var was = focusId; focusId = null; $('charttip').hidden = true;
    focus.hidden = true; document.body.classList.remove('focus-open');
    if (was && $('card-' + was)) $('card-' + was).focus({preventScroll: true});
  }
  function syncHash() { var id = location.hash.slice(1); if (!id) openedByClick = false; if (id) openFocus(id); else closeFocus(); }
  window.addEventListener('hashchange', syncHash);
  function requestClose() {
    if (openedByClick) { openedByClick = false; history.back(); return; }
    history.replaceState(null, '', location.pathname + location.search); closeFocus();
  }
  function open(id) { openedByClick = true; location.hash = id; }
  function step(dir) { if (!focusId) return; var i = (ORDER.indexOf(focusId) + dir + ORDER.length) % ORDER.length; location.replace('#' + ORDER[i]); }

  document.querySelectorAll('.card[role=button]').forEach(function (card) {
    var id = card.id.replace('card-', '');
    card.addEventListener('click', function (e) { if (e.target.closest('.tip, a, details, [data-noswipe] svg, .heatmap')) return; open(id); });
    card.addEventListener('keydown', function (e) { if ((e.key === 'Enter' || e.key === ' ') && e.target === card) { e.preventDefault(); open(id); } });
  });
  document.querySelectorAll('.kpi[data-open]').forEach(function (b) { b.addEventListener('click', function () { open(b.getAttribute('data-open')); }); });
  focus.addEventListener('click', function (e) {
    if (e.target === focus || e.target.closest('.close')) requestClose();
    else if (e.target.closest('.prev')) step(-1);
    else if (e.target.closest('.next')) step(1);
  });
  document.addEventListener('keydown', function (e) {
    if (!focusId) return;
    if (e.key === 'Escape') requestClose(); else if (e.key === 'ArrowLeft') step(-1); else if (e.key === 'ArrowRight') step(1);
  });
  // swipe between cards; charts and the heatmap keep horizontal drags for scrubbing
  var tx = null, ty = null;
  focus.addEventListener('touchstart', function (e) { if (e.target.closest('[data-noswipe]')) { tx = null; return; } tx = e.touches[0].clientX; ty = e.touches[0].clientY; }, {passive: true});
  focus.addEventListener('touchend', function (e) {
    if (tx === null) return; var dx = e.changedTouches[0].clientX - tx, dy = e.changedTouches[0].clientY - ty; tx = null;
    if (Math.abs(dx) > 60 && Math.abs(dx) > 1.5 * Math.abs(dy)) step(dx < 0 ? 1 : -1);
  }, {passive: true});
  focus.querySelector('.panel').addEventListener('scroll', function () { $('charttip').hidden = true; }, {passive: true});
  document.addEventListener('pointerdown', function (e) { if (!e.target.closest('.chart, .heatmap')) $('charttip').hidden = true; });

  // ---------- explanation bubble ----------
  var box = $('tipbox'), current = null;
  function showTip(t) {
    if (current) current.classList.remove('open');
    current = t; t.classList.add('open'); box.textContent = t.getAttribute('data-tip'); box.hidden = false;
    var r = t.getBoundingClientRect(), w = box.offsetWidth, h = box.offsetHeight;
    var left = Math.min(Math.max(8, r.left - 10), innerWidth - w - 8), top = r.bottom + 8;
    if (top + h > innerHeight - 8) top = r.top - h - 8;
    box.style.left = left + 'px'; box.style.top = Math.max(8, top) + 'px';
  }
  function hideTip() { if (current) current.classList.remove('open'); current = null; box.hidden = true; }
  document.addEventListener('pointerover', function (e) { if (e.pointerType === 'mouse' && e.target.classList && e.target.classList.contains('tip')) showTip(e.target); });
  document.addEventListener('pointerout', function (e) { if (e.pointerType === 'mouse' && e.target.classList && e.target.classList.contains('tip')) hideTip(); });
  document.addEventListener('click', function (e) { if (e.target.classList && e.target.classList.contains('tip')) { e.stopPropagation(); showTip(e.target); } else hideTip(); }, true);
  addEventListener('scroll', hideTip, {passive: true});

  load(); loadHistory();
  setInterval(load, 60000);
  setInterval(loadHistory, 600000);
  setInterval(function () { if (S) render(); }, 15000);   // keep "updated x ago" fresh
})();
