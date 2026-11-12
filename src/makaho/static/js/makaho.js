/* MAKAHO : la carte des tendances.
 *
 * Ce fichier ne calcule rien. Il dessine ce que le serveur prépare
 * (src/makaho/trends.py, src/makaho/catalogue.py) : verdicts, classes de
 * couleur, compteurs, libellés, menus, provenance. Les nombres viennent
 * tous de card-api ; ici, on ne fait que les écrire. La disposition est
 * celle de MAKAHO 1.0.0 (dev/audits/2026-11-11_v1-interface.md).
 *
 * Copyright 2026 Louis Héraut, INRAE, UR RiverLy. Licence
 * AGPL-3.0-or-later, voir le fichier LICENSE du dépôt.
 */
"use strict";

(function () {
  // ── La carte ──────────────────────────────────────────────────────
  // La vue de départ de la 1.0.0 (centre 46.80 N, 2.51 E, zoom 6 sur un
  // écran large), sans boutons de zoom : la molette, le pincement, et le
  // bouton de recentrage quand la carte a bougé. Le zoom est le plus fort
  // qui montre la France entière : 6 sur un écran large, 5 sur un
  // téléphone, comme la 1.0.0. Par niveaux entiers : entre deux, Leaflet
  // agrandit les tuiles et la carte est floue (essayé le 2026-11-12). Le
  // zoom 12 suffit pour situer une station sur sa rivière ; au-delà, le
  // fond n'apporte plus rien (2026-11-12, voulu par l'utilisateur).
  const HOME_CENTER = [46.795, 2.509];
  const FRANCE = [[41.3, -5.2], [51.1, 9.6]];

  // Le fond (décision 10) : le Plan IGN en gris clair, multiplié par
  // l'estompage du relief ; les rivières à partir d'un zoom régional.
  // Géoplateforme de l'IGN, sans jeton. Réglages choisis à l'écran le
  // 2026-11-11.
  const WMTS = "https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile"
    + "&VERSION=1.0.0&TILEMATRIXSET=PM&TILEMATRIX={z}&TILEROW={y}"
    + "&TILECOL={x}&FORMAT=image/png";
  const wmts = (layer, style) => `${WMTS}&LAYER=${layer}&STYLE=${style || "normal"}`;
  const IGN = '<a href="https://cartes.gouv.fr/">IGN, Géoplateforme</a>';

  const map = L.map("map", { zoomControl: false, minZoom: 5, maxZoom: 12 });
  const homeZoom = () => Math.min(6, map.getBoundsZoom(FRANCE));
  const goHome = () => map.setView(HOME_CENTER, homeZoom());
  goHome();
  map.attributionControl.setPrefix('<a href="https://leafletjs.com/">Leaflet</a>');
  L.tileLayer(wmts("GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2"), {
    className: "basemap-grey", opacity: 0.4, maxZoom: 18,
    attribution: `Fond ${IGN}`,
  }).addTo(map);
  L.tileLayer(wmts("ELEVATION.ELEVATIONGRIDCOVERAGE.SHADOW", "estompage_grayscale"), {
    className: "basemap-relief", opacity: 0.6, maxNativeZoom: 15, maxZoom: 18,
  }).addTo(map);
  L.tileLayer(wmts("HYDROGRAPHY.HYDROGRAPHY"), {
    opacity: 0.45, minZoom: 8, maxZoom: 18,
  }).addTo(map);
  const stationLayer = L.layerGroup().addTo(map);

  // ── Petits outils d'écriture ──────────────────────────────────────
  const $ = (id) => document.getElementById(id);
  const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

  /** Les noms viennent de Hub'Eau et de card-api : jamais insérés tels
   * quels. */
  function escape(text) {
    return String(text ?? "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    })[c]);
  }

  /** Le vrai signe moins, que les chiffres de Roboto Mono dessinent. */
  const minus = (text) => String(text).replace(/^-/, "−");

  /** Un nombre, `digits` décimales, avec un point décimal partout,
   * comme en science des données (dev/decisions.md, décision 11). */
  function num(x, digits = 2) {
    return minus(x.toFixed(digits));
  }

  /** Un nombre en notation scientifique, trois chiffres significatifs :
   * `−4.37 × 10<sup>−2</sup>`, comme dans la 1.0.0. Les chiffres en
   * chasse fixe, le « × 10 » dans la police du texte. */
  function sci(x) {
    const [mantissa, exponent] = x.toExponential(2).split("e");
    const m = `<span class="num">${num(Number(mantissa), 2)}</span>`;
    return Number(exponent) === 0 ? m
      : `${m} × 10<sup class="num">${escape(minus(Number(exponent)))}</sup>`;
  }

  /** Une unité préparée par trends.py, en morceaux (texte, exposant). */
  function unit(parts) {
    return (parts || []).map(([text, exp]) =>
      escape(text) + (exp ? `<sup>${escape(minus(exp))}</sup>` : "")).join("");
  }

  /** Une couleur de palette, ou du gris si ce n'en est pas une. */
  function color(value) {
    return /^#[0-9a-fA-F]{3,8}$/.test(value || "") ? value : "#bbbbbb";
  }

  /** Un bouton de choix, `on` s'il est pris. */
  function choice(label, on, onClick, { title = "", disabled = false } = {}) {
    const b = document.createElement("button");
    b.type = "button";
    b.className = on ? "choice on" : "choice";
    b.innerHTML = label;
    if (title) b.title = title;
    b.disabled = disabled;
    if (on) b.setAttribute("aria-pressed", "true");
    b.addEventListener("click", onClick);
    return b;
  }

  function status(text, isError = false) {
    const el = $("status");
    $("status-text").textContent = text;
    el.classList.toggle("error", isError);
    el.hidden = !text;
  }

  // ── L'état de l'analyse ───────────────────────────────────────────
  // `wanted` est ce que le panneau demande ; `page`, la dernière réponse
  // affichée. Ils diffèrent pendant un calcul, et tant qu'un curseur
  // attend « Actualiser ».
  let menus = null;              // /api/cards
  let positions = null;          // code -> position, reçues une fois
  let defaults = null;           // les réglages du service, lus dans la 1re réponse
  let page = null;
  let variableId = null;         // la variable affichée d'une fiche qui en a plusieurs
  let regimeShown = null;        // le régime dont le panneau montre les fiches
  let seasonShown = "year";
  let seq = 0;                   // seule la réponse à la dernière demande s'affiche
  const memo = new Map();        // les réponses de la visite, par réglages
  const wanted = { card: null, start: null, end: null, sampling: "preferred", level: null };

  /** Ce que le catalogue dit d'une fiche. */
  function cardInfo(id) {
    for (const r of (menus ? menus.regimes : [])) {
      const c = r.cards.find((x) => x.id === id);
      if (c) return { regime: r.id, card: c };
    }
    return null;
  }

  /** Les réglages en paramètres de /api/trend. Ce qui vaut le défaut du
   * service ne part pas : la demande retombe ainsi sur son cache. Une
   * fin au bout du curseur ne part pas non plus : l'analyse suit alors
   * la chronique jusqu'à ses dernières données. */
  function query(withPositions) {
    const q = new URLSearchParams();
    if (wanted.card) q.set("card", wanted.card);
    if (defaults) {
      if (wanted.start !== defaults.start) q.set("start", wanted.start);
      if (wanted.end !== null) q.set("end", wanted.end);
      if (wanted.level !== defaults.level) q.set("level", wanted.level);
    }
    const info = cardInfo(wanted.card);
    if (wanted.sampling !== "preferred" && info && info.card.preferred_month) {
      q.set("sampling", wanted.sampling);
    }
    if (withPositions) q.set("positions", "1");
    return q.toString();
  }

  /** Une tendance, en suivant la file de calcul s'il le faut. */
  async function fetchTrend(qs) {
    let response = await fetch(`api/trend?${qs}`);
    while (response.status === 202) {
      const pending = await response.json();
      const p = pending.progress;
      status(p && p.total
        ? `Calcul en cours (${p.done} sur ${p.total})…`
        : "Demande en file de calcul…");
      const wait = parseInt(response.headers.get("Retry-After"), 10) || 5;
      await sleep(wait * 1000);
      response = await fetch(`api/jobs/${encodeURIComponent(pending.job)}`);
    }
    const body = await response.json().catch(() => ({}));
    if (!response.ok) throw body;
    return body;
  }

  const MESSAGES = {
    unreachable: "Le service de calcul ne répond pas. Réessayez dans quelques minutes.",
    busy: "Le service de calcul est très demandé. Réessayez dans quelques minutes.",
    source: "Hub'Eau, la source des débits, ne répond pas. Réessayez plus tard.",
    no_data: "Aucune station de la liste n'a de débits à analyser.",
    key: "MAKAHO n'a plus accès au service de calcul. Le problème est signalé.",
    job: "Le calcul demandé a échoué ou a expiré. Rechargez la page pour le relancer.",
  };

  /** Lance l'analyse que le panneau demande, et l'affiche. Une réponse
   * déjà reçue pendant la visite revient sans rien redemander. */
  async function analyse() {
    const mine = ++seq;
    pending(false);
    // La clé et la demande sont prises maintenant : le panneau peut
    // changer pendant le calcul.
    let key = defaults ? query(false) : null;
    const qs = query(!positions);
    let result = key && memo.get(key);
    if (!result) {
      document.body.classList.add("busy");
      status("Calcul des tendances…");
      try {
        result = await fetchTrend(qs);
      } catch (error) {
        // La première demande joint les positions, que card-api lit chez
        // Hub'Eau à chaque appel ; quand Hub'Eau traîne, toute la réponse
        // tombe (signalé à card-api le 2026-11-12). Une seconde tentative,
        // une seule : la tendance est alors déjà en cache chez lui.
        if (!positions && error && error.error === "source") {
          try {
            await sleep(2000);
            result = await fetchTrend(qs);
          } catch (again) {
            error = again;
          }
        }
        if (!result) {
          if (mine === seq) {
            document.body.classList.remove("busy");
            const known = error && MESSAGES[error.error];
            status(known || "La carte n'a pas pu se charger. Réessayez dans un moment.", true);
            if (!known) console.error(error);
          }
          return;
        }
      }
      if (!defaults) {
        firstResult(result);
        key = query(false);
      }
      memo.set(key, result);
    }
    if (mine !== seq) return;
    document.body.classList.remove("busy");
    status("");
    show(result);
  }

  /** La première réponse donne les positions et les réglages par défaut
   * du service, que le panneau prend pour point de départ. */
  function firstResult(result) {
    positions = new Map((result.positions || []).map((p) => [p.code, p]));
    const prov = result.provenance;
    defaults = {
      start: Number(String(prov.period.start).slice(0, 4)),
      level: prov.level,
    };
    wanted.card = result.card;
    wanted.start = defaults.start;
    wanted.level = defaults.level;
    drawInfo(prov);
  }

  function show(result) {
    page = result;
    if (!page.variables.some((v) => v.id === variableId)) {
      variableId = page.variables[0].id;
    }
    draw();
    drawPanel();
  }

  function draw() {
    const v = page.variables.find((x) => x.id === variableId);
    drawStations(v);
    drawSummary(v, page.provenance);
    drawColorbar(v);
    drawCounts(v, page.omitted);
  }

  // ── Les stations ──────────────────────────────────────────────────

  /** La forme dit le verdict ; une chronique trop courte est un rond
   * cerclé de jaune, une station sans tendance un rond vide. */
  function look(s) {
    if (s.trend == null) return { css: "missing", symbol: "none" };
    if (s.short) return { css: "short", symbol: "short" };
    return { css: s.trend, symbol: s.trend };
  }

  /** L'infobulle de la 1.0.0 : le code et le nom, les pentes dans la
   * couleur de la station, la position. */
  function tooltip(s, pos, v, fill) {
    const slopes = [];
    if (s.a != null) {
      slopes.push(`<b>${sci(s.a)}</b> <span class="unit">[${unit(v.units.absolute)}]</span>`);
    }
    if (s.a_relative != null) {
      slopes.push(`<b class="num">${num(s.a_relative, 2)}</b> <span class="unit">[${unit(v.units.relative)}]</span>`);
    }
    return `<div class="head"><span class="code">${escape(s.code)}</span> - ${escape(pos.name || "")}</div>`
      + (slopes.length ? `<div class="slopes" style="color:${fill}">${slopes.join(" ")}</div>` : "")
      + "<table><tr>"
      + `<td>Lat : <span class="num">${num(pos.lat, 4)}</span></td>`
      + `<td>Long : <span class="num">${num(pos.lon, 4)}</span></td>`
      + "</tr></table>";
  }

  function drawStations(v) {
    stationLayer.clearLayers();
    for (const s of v.stations) {
      const pos = positions.get(s.code);
      if (!pos || pos.lat == null || pos.lon == null) continue;
      const { css, symbol } = look(s);
      const fill = s.class == null ? "#ffffff" : color(v.palette[s.class]);
      const icon = L.divIcon({
        className: `station ${css}`,
        html: `<svg class="marker" viewBox="0 0 24 24" style="--fill:${fill}"><use href="#m-${symbol}"/></svg>`,
        iconSize: [32, 32],
      });
      const significant = !s.short && (s.trend === "up" || s.trend === "down");
      L.marker([pos.lat, pos.lon], {
        icon, keyboard: false, zIndexOffset: significant ? 1000 : 0,
      })
        .bindTooltip(tooltip(s, pos, v, fill), {
          className: "station-tip", direction: "auto", offset: [8, 0],
        })
        .addTo(stationLayer);
    }
  }

  // ── Les panneaux de droite ────────────────────────────────────────

  function drawSummary(v, prov) {
    $("card-id").textContent = v.id;
    $("card-name").textContent = v.name || "";
    $("card-sampling").innerHTML = v.sampling
      ? `Année hydrologique<br>${escape(v.sampling)}` : "";
    // La période demandée, comme le curseur de la 1.0.0. Sans fin
    // demandée, l'analyse va jusqu'aux dernières données.
    const period = prov.period || {};
    const year = (date) => escape(String(date).slice(0, 4));
    $("card-period").innerHTML = period.start && period.end
      ? `Période <span class="num">${year(period.start)}</span> - <span class="num">${year(period.end)}</span>`
      : period.start ? `Période depuis <span class="num">${year(period.start)}</span>` : "";
    $("card-level").innerHTML = prov.level != null
      ? `Significativité de <span class="num">${num(prov.level * 100, 0)}%</span>` : "";
    $("summary").hidden = false;
  }

  /** La barre de couleur de la 1.0.0 : verticale, les classes positives
   * en haut, les deux classes ouvertes en pointe, les bornes à droite et
   * le titre à gauche, de bas en haut. */
  function drawColorbar(v) {
    const k = v.palette.length, inner = k - 2;
    const W = 84, H = 262, x = 24, w = 15, arrow = 14;
    const top = 2, bottom = H - 2;
    const box = (bottom - top - 2 * arrow) / inner;
    const parts = [];
    v.palette.forEach((c, i) => {
      const fill = color(c);
      if (i === 0) {
        const y = bottom - arrow;
        parts.push(`<polygon fill="${fill}" points="${x},${y} ${x + w},${y} ${x + w / 2},${bottom}"/>`);
      } else if (i === k - 1) {
        const y = top + arrow;
        parts.push(`<polygon fill="${fill}" points="${x},${y} ${x + w},${y} ${x + w / 2},${top}"/>`);
      } else {
        const y = bottom - arrow - i * box;
        parts.push(`<rect fill="${fill}" x="${x}" y="${y}" width="${w}" height="${box + 0.3}"/>`);
      }
    });
    v.edges.forEach((edge, j) => {
      const y = bottom - arrow - j * box;
      const label = Math.abs(edge) < 1e-12 ? "0" : num(edge, v.digits);
      parts.push(`<text class="tick" x="${x + w + 5}" y="${y}" dominant-baseline="middle">${escape(label)}</text>`);
    });
    const unitText = (v.units.bar || []).map(([text, exp]) =>
      escape(text) + (exp ? `<tspan baseline-shift="super" font-size="8">${escape(minus(exp))}</tspan>` : "")).join("");
    parts.push(`<text transform="translate(10 ${H / 2}) rotate(-90)" text-anchor="middle" dominant-baseline="middle">`
      + `<tspan class="title">TENDANCES OBSERVÉES</tspan><tspan class="unit"> ${unitText}</tspan></text>`);
    $("colorbar").innerHTML = `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" `
      + `aria-label="Classes de pente, ${escape(v.units.bar.map((p) => p[0]).join(""))}">${parts.join("")}</svg>`;
    $("colorbar").hidden = false;
  }

  function drawCounts(v, omitted) {
    const s = v.summary;
    const lines = [
      `<span class="num">${s.total}</span> stations au total`,
      `∆ <span class="num">${s.up}</span> hausse${s.up > 1 ? "s" : ""} significative${s.up > 1 ? "s" : ""}`,
      `∇ <span class="num">${s.down}</span> baisse${s.down > 1 ? "s" : ""} significative${s.down > 1 ? "s" : ""}`,
    ];
    if (omitted.length) {
      lines.push(`<span class="num">${omitted.length}</span> écartée${omitted.length > 1 ? "s" : ""}, sans débits`);
    }
    $("counts").innerHTML = lines.map((l) => `<p>${l}</p>`).join("");
    $("counts").hidden = false;
  }

  /** La provenance, dans le panneau d'information : là où la 1.0.0
   * disait la date de ses données. */
  function drawInfo(prov) {
    const read = prov.data_fetched_at
      ? new Date(prov.data_fetched_at).toLocaleDateString("fr-FR") : null;
    $("info-data").innerHTML = read ? `, lus le <span class="num">${escape(read)}</span>` : "";
    const versions = [];
    if (prov.api_version) versions.push(`<span class="num">${escape(prov.api_version)}</span>`);
    const deps = [["card", prov.card_version], ["stase", prov.stase_version]]
      .filter(([, ver]) => ver)
      .map(([name, ver]) => `${name} <span class="num">${escape(ver)}</span>`);
    if (deps.length) versions.push(`(${deps.join(", ")})`);
    $("info-compute").innerHTML = versions.length ? ` ${versions.join(" ")}` : "";
  }

  // ── Le panneau d'analyse ──────────────────────────────────────────

  const monthInput = $("month"), startInput = $("start"), endInput = $("end");

  /** Le panneau, d'après `wanted` et la réponse affichée. */
  function drawPanel() {
    if (!menus || !defaults) return;
    const info = cardInfo(wanted.card);
    if (!regimeShown) {
      regimeShown = info ? info.regime : menus.regimes[0].id;
      seasonShown = info ? info.card.season : "year";
    }
    const v = page && page.variables.find((x) => x.id === variableId);
    $("analysis-title").innerHTML = v
      ? `<span class="code">${escape(v.id)}</span> : ${escape(v.name || "")}` : "";

    $("regimes").replaceChildren(...menus.regimes.map((r) => choice(
      escape(r.label), r.id === regimeShown, () => {
        regimeShown = r.id;
        const own = info && info.regime === r.id;
        seasonShown = own ? info.card.season : r.seasons[0].id;
        drawPanel();
      })));

    const regime = menus.regimes.find((r) => r.id === regimeShown);
    $("seasons").replaceChildren(...(regime.seasons.length > 1 ? regime.seasons : [])
      .map((s) => choice(escape(s.label), s.id === seasonShown, () => {
        seasonShown = s.id;
        drawPanel();
      })));
    $("cards").replaceChildren(...regime.cards
      .filter((c) => c.season === seasonShown)
      .map((c) => choice(
        escape(c.label) + (c.sub ? `<sub>${escape(c.sub)}</sub>` : ""),
        c.id === wanted.card, () => {
          if (c.id === wanted.card) return;
          wanted.card = c.id;
          analyse();
          drawPanel();
        }, { title: c.name || "" })));

    // Les variables d'une fiche qui en a plusieurs (QMA, un mois par
    // variable) : elles sont toutes dans la réponse, on passe de l'une à
    // l'autre sans rien redemander.
    const shownCard = page && cardInfo(page.card);
    const many = shownCard && page.card === wanted.card && shownCard.card.variables;
    $("variables").replaceChildren(...(many || []).map((x) => choice(
      escape(x.label), x.id === variableId, () => {
        variableId = x.id;
        draw();
        drawPanel();
      }, { title: x.name || "" })));

    // L'année hydrologique : le mois de départ, ou « Optimale », le
    // départ fixe que déclare la fiche (protocole MAKAHO). Sans départ
    // déclaré (une variable mensuelle), le réglage n'a pas d'objet.
    const preferred = info && info.card.preferred_month;
    const month = wanted.sampling === "preferred"
      ? preferred : Number(wanted.sampling.slice(0, 2));
    monthInput.disabled = !preferred;
    if (month) monthInput.value = month;
    drawMonthTicks(month);
    const optimal = $("optimal");
    optimal.className = wanted.sampling === "preferred" && preferred ? "choice on" : "choice";
    optimal.disabled = !preferred;

    drawPeriod();

    $("levels").replaceChildren(...menus.levels.map((l) => choice(
      `<span class="num">${num(l * 100, 0)}%</span>`, l === wanted.level, () => {
        if (l === wanted.level) return;
        wanted.level = l;
        analyse();
        drawPanel();
      })));
  }

  function drawMonthTicks(month) {
    $("month-ticks").innerHTML = menus.months.map((m, i) =>
      `<span class="${i + 1 === month ? "on" : ""}">${escape(m)}</span>`).join("");
  }

  /** Le curseur de période : de la première année du curseur à l'année
   * en cours ; une fin au bout du curseur suit les dernières données. */
  function drawPeriod() {
    const last = new Date().getFullYear();
    for (const input of [startInput, endInput]) {
      input.min = menus.period.first;
      input.max = last;
    }
    startInput.value = wanted.start;
    endInput.value = wanted.end ?? last;
    $("period-values").innerHTML = `<span class="num">${escape(startInput.value)}</span>`
      + ` - <span class="num">${escape(endInput.value)}</span>`;
  }

  /** Un curseur a bougé : rien ne part avant « Actualiser ». */
  function pending(on) {
    $("refresh").hidden = !on;
  }

  monthInput.addEventListener("input", () => {
    const m = Number(monthInput.value);
    wanted.sampling = `${String(m).padStart(2, "0")}-01`;
    drawMonthTicks(m);
    $("optimal").className = "choice";
    pending(true);
  });

  $("optimal").addEventListener("click", () => {
    if (wanted.sampling === "preferred") return;
    wanted.sampling = "preferred";
    analyse();
    drawPanel();
  });

  // Le garde-fou des trente ans : les deux bornes restent à au moins
  // `min_years` valeurs l'une de l'autre, la borne qu'on ne tient pas
  // est poussée.
  function periodInput(moved) {
    const gap = menus.period.min_years - 1, last = new Date().getFullYear();
    let start = Number(startInput.value), end = Number(endInput.value);
    if (end - start < gap) {
      if (moved === startInput) end = Math.min(last, start + gap);
      else start = Math.max(menus.period.first, end - gap);
      if (end - start < gap) {
        if (moved === startInput) start = end - gap;
        else end = start + gap;
      }
    }
    wanted.start = start;
    wanted.end = end >= last ? null : end;
    drawPeriod();
    pending(true);
  }
  startInput.addEventListener("input", () => periodInput(startInput));
  endInput.addEventListener("input", () => periodInput(endInput));

  $("refresh").addEventListener("click", analyse);

  // ── Les boutons ───────────────────────────────────────────────────

  const recenter = $("recenter");
  recenter.addEventListener("click", goHome);
  map.on("moveend", () => {
    const home = map.getZoom() === homeZoom()
      && map.latLngToContainerPoint(HOME_CENTER).distanceTo(map.getSize().divideBy(2)) < 2;
    recenter.hidden = home;
  });

  /** Un bouton qui ouvre et ferme son panneau ; la page porte la classe
   * `<panneau>-open` tant qu'il est ouvert. */
  function toggles(button, panel) {
    button.addEventListener("click", () => {
      panel.hidden = !panel.hidden;
      button.setAttribute("aria-expanded", String(!panel.hidden));
      document.body.classList.toggle(`${panel.id}-open`, !panel.hidden);
    });
  }
  toggles($("info-button"), $("info"));
  toggles($("analysis-button"), $("analysis"));
  document.addEventListener("keydown", (e) => {
    if (e.key !== "Escape") return;
    for (const [button, panel] of [["info-button", "info"], ["analysis-button", "analysis"]]) {
      if (!$(panel).hidden) $(button).click();
    }
  });

  // ── Le chargement ─────────────────────────────────────────────────
  // La carte et les menus partent ensemble : le catalogue de card-api
  // met quelques secondes à venir, il ne retarde pas la carte.

  analyse();
  fetch("api/cards")
    .then((r) => (r.ok ? r.json() : Promise.reject(r)))
    .then((body) => {
      menus = body;
      $("analysis-button").hidden = false;
      drawPanel();
    })
    .catch((error) => console.error("menus indisponibles", error));
})();
