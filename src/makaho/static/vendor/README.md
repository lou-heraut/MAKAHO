# Bibliothèques copiées dans le dépôt

Servies par MAKAHO lui-même plutôt que par un CDN : un service public
n'envoie pas l'adresse de ses visiteurs à un tiers, et la page ne dépend
pas d'un autre site.

- `leaflet-1.9.4/` : Leaflet 1.9.4, licence BSD-2-Clause (`LICENSE`).
  Pris le 2026-11-11 dans l'archive npm (`leaflet-1.9.4.tgz`), dont
  l'empreinte sha512 a été vérifiée contre celle que publie le registre.
  Seuls `dist/leaflet.js`, `dist/leaflet.css` et les icônes du sélecteur
  de couches sont gardés. Pour changer de version : refaire ces gestes,
  dans un nouveau dossier au nom de la version.
- `inter-5.3.0/`, `raleway-5.3.0/`, `roboto-mono-5.3.0/` : les polices
  Inter (texte), Raleway (titres) et Roboto Mono (chiffres et codes),
  licence SIL Open Font License 1.1 (`LICENSE` de chacune). Prises le
  2026-11-11 dans les archives npm de Fontsource
  (`@fontsource-variable/<nom>`, version 5.3.0), empreintes sha512
  vérifiées contre celles du registre. Seul le fichier variable du jeu
  de caractères latin est gardé (`*-latin-wght-normal.woff2`) : il
  couvre le français, œ compris. Sa plage Unicode est recopiée dans
  `css/makaho.css` ; les caractères hors plage (∆, ∇) viennent de la
  police de repli. Pour changer de version : mêmes gestes, nouveau
  dossier.
