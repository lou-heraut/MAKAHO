/* MAKAHO : la carte des tendances.
 *
 * Ce fichier ne calcule rien. Il dessine ce que le serveur prépare
 * (src/makaho/trends.py) : verdicts, classes de couleur, histogramme,
 * résumé, provenance. Les nombres viennent tous de card-api.
 *
 * Copyright 2026 Louis Héraut, INRAE, UR RiverLy. Licence
 * AGPL-3.0-or-later, voir le fichier LICENSE du dépôt.
 */
"use strict";

(function () {
  // ── Le fond de carte (décision 10) ────────────────────────────────
  // Le Plan IGN en gris clair, multiplié par l'estompage du relief ; les
  // rivières à partir d'un zoom régional. Géoplateforme de l'IGN, sans
  // jeton. Les réglages ont été choisis à l'écran le 2026-11-11.
  const WMTS = "https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile"
    + "&VERSION=1.0.0&TILEMATRIXSET=PM&TILEMATRIX={z}&TILEROW={y}"
    + "&TILECOL={x}&FORMAT=image/png";
  const wmts = (layer, style) => `${WMTS}&LAYER=${layer}&STYLE=${style || "normal"}`;
  const IGN = '<a href="https://cartes.gouv.fr/">IGN, Géoplateforme</a>';

  const map = L.map("map", { zoomSnap: 0.5, minZoom: 5, maxZoom: 14 })
    .setView([46.6, 2.5], 6);
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

  // ── Petits outils ─────────────────────────────────────────────────
  const $ = (id) => document.getElementById(id);
  const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

  /** Un nombre à la française, `digits` décimales. */
  function num(x, digits = 2) {
    if (x === null || x === undefined) return "non calculée";
    return x.toLocaleString("fr-FR", {
      minimumFractionDigits: digits, maximumFractionDigits: digits,
    });
  }

  /** Les noms viennent de Hub'Eau : jamais insérés tels quels. */
  function escape(text) {
    return String(text ?? "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    })[c]);
  }

  /** Une couleur de palette, ou du gris si ce n'en est pas une. */
  function color(value) {
    return /^#[0-9a-fA-F]{3,8}$/.test(value || "") ? value : "#bbbbbb";
  }

  function status(text, isError = false) {
    const el = $("status");
    el.textContent = text;
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
  };

  // ── Le dessin ─────────────────────────────────────────────────────

  const VERDICT = {
    up: "Hausse significative",
    down: "Baisse significative",
    none: "Pas de tendance significative",
  };

  function tooltip(station, position, variable) {
    const verdict = VERDICT[station.trend];
    const lines = [
      `<strong>${escape(position.name || station.code)}</strong>`,
      `<span class="code">${escape(station.code)}</span>`,
    ];
    if (verdict) {
      lines.push(`${verdict}, ${num(station.slope)} ${escape(variable.unit)}`);
      lines.push(`p = ${num(station.p, 3)}, sur ${station.n} années`);
    } else {
      lines.push("Tendance non calculée");
    }
    return lines.join("<br>");
  }

  function drawStations(page) {
    const variable = page.variable;
    const where = new Map((page.positions || []).map((p) => [p.code, p]));
    const points = [];
    for (const s of page.stations) {
      const pos = where.get(s.code);
      if (!pos || pos.lat == null || pos.lon == null) continue;
      const significant = s.trend === "up" || s.trend === "down";
      const size = significant ? 16 : 12;
      const fill = s.class == null ? "#ffffff" : color(variable.palette[s.class]);
      const icon = L.divIcon({
        className: `station ${s.trend || "gap"}`,
        html: `<svg class="marker" style="--fill:${fill}"><use href="#m-${s.trend || "none"}"/></svg>`,
        iconSize: [size, size],
      });
      L.marker([pos.lat, pos.lon], { icon, keyboard: false, riseOnHover: true })
        .bindTooltip(tooltip(s, pos, variable), {
          direction: "top", offset: [0, -size / 2],
        })
        .addTo(map);
      points.push([pos.lat, pos.lon]);
    }
    return points;
  }

  /** Cadrer les stations. Un panneau qui couvre presque toute la largeur
   * (sur un téléphone) cacherait des stations : on cadre au-dessous du
   * titre et au-dessus de la légende. */
  function fit(points) {
    if (!points.length) return;
    const width = map.getSize().x;
    const covers = (el) => !el.hidden && el.offsetWidth > 0.6 * width;
    const title = $("title").closest(".panel"), legend = $("legend");
    const top = covers(title) ? title.offsetTop + title.offsetHeight + 10 : 30;
    const bottom = covers(legend) ? legend.offsetHeight + 40 : 30;
    map.fitBounds(points, { paddingTopLeft: [30, top], paddingBottomRight: [30, bottom] });
  }

  /** La barre de couleur, avec au-dessus l'histogramme des pentes : la
   * classe et sa population au même endroit. Les classes extrêmes sont
   * ouvertes, d'où leurs bouts en pointe. */
  function colorbar(variable) {
    const k = variable.palette.length;
    const W = 260, barH = 34, colH = 12, w = W / k, y = barH + 3;
    const max = Math.max(1, ...variable.histogram);
    const parts = [];
    variable.histogram.forEach((n, i) => {
      const h = (barH * n) / max;
      parts.push(`<rect class="bar" x="${i * w + 2}" y="${barH - h}" width="${w - 4}" height="${h}"><title>${n} station${n > 1 ? "s" : ""}</title></rect>`);
    });
    variable.palette.forEach((c, i) => {
      const x = i * w, fill = color(c);
      if (i === 0) {
        parts.push(`<polygon class="class" fill="${fill}" points="${x},${y + colH / 2} ${x + w},${y} ${x + w},${y + colH}"/>`);
      } else if (i === k - 1) {
        parts.push(`<polygon class="class" fill="${fill}" points="${x},${y} ${x + w},${y + colH / 2} ${x},${y + colH}"/>`);
      } else {
        parts.push(`<rect class="class" fill="${fill}" x="${x}" y="${y}" width="${w}" height="${colH}"/>`);
      }
    });
    variable.edges.forEach((edge, j) => {
      if (j % 2) return;                      // une borne sur deux, lisible
      const label = Math.abs(edge) < 1e-12 ? "0" : num(edge);
      parts.push(`<text class="tick" x="${(j + 1) * w}" y="${y + colH + 13}">${label}</text>`);
    });
    return `<svg viewBox="0 0 ${W} ${y + colH + 17}" role="img" aria-label="Classes de pente et nombre de stations par classe">${parts.join("")}</svg>`;
  }

  function drawLegend(page) {
    const v = page.variable, s = page.summary, prov = page.provenance;
    const period = prov.period || {};
    const since = period.start ? `depuis ${period.start.slice(0, 4)}` : "toute la chronique";
    $("title").textContent = `${v.name} (${v.id})`;
    $("subtitle").textContent = `RRSE, ${s.total} stations, ${since}, `
      + `Mann-Kendall ${prov.mk}, risque ${num(prov.level * 100, 0)} %`;
    $("unit").textContent = v.relative
      ? "Pente de Sen relative, en % par an"
      : `Pente de Sen, en ${v.unit}`;
    $("colorbar").innerHTML = colorbar(v);
    let summary = `${s.down} en baisse, ${s.up} en hausse, ${s.none} sans `
      + `tendance significative. Pente médiane : ${num(s.median)} ${v.unit}.`;
    if (page.omitted.length) {
      summary += ` ${page.omitted.length} station(s) écartée(s), sans débits.`;
    }
    $("summary").textContent = summary;
    const read = prov.data_fetched_at
      ? new Date(prov.data_fetched_at).toLocaleDateString("fr-FR") : "?";
    $("provenance").innerHTML = `Débits <a href="https://hubeau.eaufrance.fr/">Hub'Eau</a> lus le ${escape(read)}, `
      + `calcul <a href="https://card-api.riverly.inrae.fr/">card-api</a> ${escape(prov.api_version)} `
      + `(card ${escape(prov.card_version)}, stase ${escape(prov.stase_version)})`;
    $("legend").hidden = false;
  }

  load()
    .then((page) => {
      const points = drawStations(page);
      drawLegend(page);
      status("");
      fit(points);
    })
    .catch((error) => {
      const known = error && MESSAGES[error.error];
      status(known || "La carte n'a pas pu se charger. Réessayez dans un moment.", true);
      if (!known) console.error(error);
    });
})();
