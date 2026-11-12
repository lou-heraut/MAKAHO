/* MAKAHO : la carte des tendances.
 *
 * Ce fichier ne calcule rien. Il dessine ce que le serveur prépare
 * (src/makaho/trends.py) : verdicts, classes de couleur, compteurs,
 * libellés, provenance. Les nombres viennent tous de card-api ; ici, on
 * ne fait que les écrire. La disposition est celle de MAKAHO 1.0.0
 * (dev/audits/2026-11-11_v1-interface.md).
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

  // ── Petits outils d'écriture ──────────────────────────────────────
  const $ = (id) => document.getElementById(id);
  const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

  /** Les noms viennent de Hub'Eau : jamais insérés tels quels. */
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

  function status(text, isError = false) {
    const el = $("status");
    $("status-text").textContent = text;
    el.classList.toggle("error", isError);
    el.hidden = !text;
  }

  // ── Les données ───────────────────────────────────────────────────

  /** La tendance pour la page, en suivant la file de calcul s'il le faut. */
  async function load() {
    let response = await fetch("api/trend?positions=1");
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

  function drawStations(page) {
    const v = page.variable;
    const where = new Map((page.positions || []).map((p) => [p.code, p]));
    for (const s of page.stations) {
      const pos = where.get(s.code);
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
        .addTo(map);
    }
  }

  // ── Les panneaux de droite ────────────────────────────────────────

  function drawSummary(page) {
    const v = page.variable, prov = page.provenance;
    $("card-id").textContent = v.id;
    $("card-name").textContent = v.name || "";
    $("card-sampling").innerHTML = v.sampling
      ? `Année hydrologique<br>${escape(v.sampling)}` : "";
    // La période demandée, comme le curseur de la 1.0.0. Sans fin
    // demandée, l'analyse va jusqu'aux dernières données (M3 donnera la
    // borne de fin, avec son curseur).
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

  function drawCounts(page) {
    const s = page.summary;
    const lines = [
      `<span class="num">${s.total}</span> stations au total`,
      `∆ <span class="num">${s.up}</span> hausse${s.up > 1 ? "s" : ""} significative${s.up > 1 ? "s" : ""}`,
      `∇ <span class="num">${s.down}</span> baisse${s.down > 1 ? "s" : ""} significative${s.down > 1 ? "s" : ""}`,
    ];
    if (page.omitted.length) {
      lines.push(`<span class="num">${page.omitted.length}</span> écartée${page.omitted.length > 1 ? "s" : ""}, sans débits`);
    }
    $("counts").innerHTML = lines.map((l) => `<p>${l}</p>`).join("");
    $("counts").hidden = false;
  }

  /** La provenance, dans le panneau d'information : là où la 1.0.0
   * disait la date de ses données. */
  function drawInfo(prov) {
    const read = prov.data_fetched_at
      ? new Date(prov.data_fetched_at).toLocaleDateString("fr-FR") : null;
    if (read) $("info-data").insertAdjacentHTML("beforeend", `, lus le <span class="num">${escape(read)}</span>`);
    const versions = [];
    if (prov.api_version) versions.push(`<span class="num">${escape(prov.api_version)}</span>`);
    const deps = [["card", prov.card_version], ["stase", prov.stase_version]]
      .filter(([, ver]) => ver)
      .map(([name, ver]) => `${name} <span class="num">${escape(ver)}</span>`);
    if (deps.length) versions.push(`(${deps.join(", ")})`);
    if (versions.length) $("info-compute").insertAdjacentHTML("beforeend", ` ${versions.join(" ")}`);
  }

  // ── Les boutons ───────────────────────────────────────────────────

  const recenter = $("recenter");
  recenter.addEventListener("click", goHome);
  map.on("moveend", () => {
    const home = map.getZoom() === homeZoom()
      && map.latLngToContainerPoint(HOME_CENTER).distanceTo(map.getSize().divideBy(2)) < 2;
    recenter.hidden = home;
  });

  const infoButton = $("info-button"), info = $("info");
  infoButton.addEventListener("click", () => {
    info.hidden = !info.hidden;
    infoButton.setAttribute("aria-expanded", String(!info.hidden));
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !info.hidden) infoButton.click();
  });

  // ── Le chargement ─────────────────────────────────────────────────

  load()
    .then((page) => {
      drawStations(page);
      drawSummary(page);
      drawColorbar(page.variable);
      drawCounts(page);
      drawInfo(page.provenance);
      status("");
    })
    .catch((error) => {
      const known = error && MESSAGES[error.error];
      status(known || "La carte n'a pas pu se charger. Réessayez dans un moment.", true);
      if (!known) console.error(error);
    });
})();
