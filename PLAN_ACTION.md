# Plan d'action — Macros GCODE TPU FDM
> Repo : MollyMoxley/rex-tpu-fdm  
> Dernière mise à jour : 2026-03-20  
> Statut : Phase 1 en cours

---

## Contexte

Le repo contient un REX TPU 85A NinjaFlex validé (Bambu A1, 0.4mm, 229°C).  
L'objectif est d'étendre ce travail en un système de profils par matière et par machine,
avec macros GCODE actionnables et intégration Notion.

**Parc machines concerné**
| ID | Machine | Firmware |
|----|---------|----------|
| EX0 | Qidi X-Max 3 | Klipper |
| EX1 | Artillery Sidewinder X2 | Klipper (projet Ethereal) |
| EX3 | Bambu Lab A1 | BambuStudio / OrcaSlicer |

---

## Phase 1 — Fiches matière

> Objectif : une fiche par grade TPU avec tous les paramètres de référence.

### TPU 98A — Profil production (priorité 1)
- **Statut** : à créer (pas encore de REX dédié)
- **Rôle** : grade production recommandé — rhéologie plus stable que 85A
- **Machines cibles** : EX1, EX3
- **Paramètres de départ estimés** (à valider par DOE)

| Paramètre | Valeur estimée | Unité | Source |
|-----------|---------------|-------|--------|
| Temp. buse | 220–225 | °C | extrapolé 85A |
| Temp. plateau | 40–50 | °C | spec fabricant |
| Flow | 1.00 | — | point de départ |
| Débit vol. max | 2.0–3.0 | mm³/s | shore plus élevé = plus fluide |
| Rétraction | 0.30–0.50 | mm | à tester |
| Vitesse rétract. | 15–20 | mm/s | |
| Wipe | 0.5–0.8 | mm | |
| Ventilation | 20–35 | % | solidification plus rapide |
| Vitesse mur ext | 30–40 | mm/s | |
| Avoid crossing | ON / 8mm | — | hérité 85A |

- **Fichiers à produire** : `profiles/tpu98a/bambu_a1_0.4mm.json`, `macros/klipper/tpu98a_start.cfg`

---

### TPU 85A NinjaFlex — Profil proto/R&D (REX validé)
- **Statut** : ✅ REX v2.0 validé — `rex/REX_TPU85A_NinjaFlex_BambuA1_0.4mm_229C_v2.html`
- **Rôle** : proto / R&D — NE PAS utiliser en production (lot vieilli ~3 ans)
- **Machine validée** : EX3 Bambu A1

| Paramètre | Valeur validée | Unité | Note |
|-----------|---------------|-------|------|
| Temp. buse | **229** | °C | Point critique ±2°C = sortie de régime |
| Temp. plateau | 55 | °C | |
| Flow | 1.02 | — | conservateur |
| Débit vol. max | **1.42** | mm³/s | limite haute matière vieillie |
| Rétraction | 0.32 | mm | levier mineur TPU |
| Vitesse rétract. | 11 | mm/s | |
| Wipe | **0.75** | mm | levier clé anti-blobs |
| Ventilation | 10–18 | % | solidification contrôlée |
| Accélération | 650 | mm/s² | |
| Vitesse mur ext | 23 | mm/s | |
| Vitesse mur int | 30 | mm/s | |
| Hauteur couche | 0.20 | mm | |
| Largeur ligne | 0.48 | mm | |
| Avoid crossing | **ON / 8mm** | — | levier slicer dominant −60% stringing |

**Hiérarchie des leviers (issue du REX)**
1. Qualité matière (séchage 45°C / 10h obligatoire)
2. Température buse (229°C — point précis, pas une plage)
3. Débit volumique max
4. Ventilation
5. Wipe
6. Rétraction (levier faible pour TPU)
7. Trajectoires slicer — Avoid Crossing (levier slicer dominant)

**Limite identifiée** : stringing résiduel irréductible par slicer = limite physique matière vieillie.

- **Fichiers à produire** : `profiles/tpu85a/bambu_a1_0.4mm.json`, `macros/klipper/tpu85a_start.cfg`

---

### TPU 70D Recreus — À qualifier (FDS réel)
- **Statut** : ⚠️ non testé — qualification nécessaire
- **Rôle** : grade rigide (Shore 70D ≠ Shore A) — comportement différent
- **Note** : 70D = bien plus rigide, T buse probablement 215–220°C, rétraction plus agressive possible
- **Baseline** : paramètres 85A comme point de départ du DOE

| Paramètre | Valeur de départ (extrapolée) | À confirmer |
|-----------|-------------------------------|-------------|
| Temp. buse | 215–220 | °C |
| Temp. plateau | 45–50 | °C |
| Flow | 1.00–1.02 | — |
| Débit vol. max | 1.5–2.0 | mm³/s | rigidité → meilleure tenue |
| Rétraction | 0.40–0.60 | mm | plus rigide = rétract possible |
| Ventilation | 15–25 | % | |
| Avoid crossing | ON / 8mm | — | à conserver par défaut |

**Action requise** : DOE Taguchi L8 — variables : T buse, flow, rétraction, fan, wipe.  
Résultat attendu : nouveau REX v1 TPU70D.

- **Fichiers à produire** : `profiles/tpu70d/template.json`, `rex/DOE_TPU70D_L8_template.xlsx`

---

## Phase 2 — Macros GCODE par matière

### Klipper (EX1 Artillery Sidewinder X2 — projet Ethereal)

Syntaxe Klipper — macros avec variables dynamiques :

```ini
# macros/klipper/tpu98a_start.cfg
[gcode_macro PRINT_START_TPU98A]
description: Démarrage impression TPU 98A — EX1
gcode:
    M117 TPU 98A — séchage 45C/10h requis
    M109 S222        ; Température buse 98A
    M190 S45         ; Plateau
    M106 S64         ; Ventilation 25% (64/255)
    G28              ; Homing
    BED_MESH_CALIBRATE
    G1 Z5 F600
    G1 X0 Y0 F3000
    M117 Impression en cours...

[gcode_macro PRINT_END_TPU]
description: Fin impression TPU — universel
gcode:
    M104 S0
    M140 S0
    G91
    G1 Z10 F600
    G90
    G1 X0 Y200 F3000
    M84
    M117 Impression terminée
```

```ini
# macros/klipper/tpu85a_start.cfg
[gcode_macro PRINT_START_TPU85A]
description: Démarrage impression TPU 85A NinjaFlex — EX1
gcode:
    M117 TPU 85A — séchage 45C/10h OBLIGATOIRE
    M109 S229        ; 229°C — point critique ±2°C
    M190 S55
    M106 S38         ; Ventilation 15% (38/255)
    G28
    BED_MESH_CALIBRATE
    G1 Z5 F600
    G1 X0 Y0 F3000
    M117 Impression en cours...
```

### OrcaSlicer / BambuStudio (EX3 Bambu A1)

Profils filament JSON — à importer dans OrcaSlicer (`Filament > Import`).  
Fichiers : `profiles/tpu85a/bambu_a1_0.4mm.json`, `profiles/tpu98a/bambu_a1_0.4mm.json`

Paramètres clés encodés dans le JSON :
- `nozzle_temperature` / `nozzle_temperature_initial_layer`
- `filament_max_volumetric_speed`
- `retraction_length` / `retraction_speed`
- `wipe_distance`
- `fan_cooling_layer_time` / `fan_min_speed` / `fan_max_speed`

---

## Phase 3 — Structure repo cible

```
rex-tpu-fdm/
├── README.md                          ← vue d'ensemble + tableau des grades
├── PLAN_ACTION.md                     ← ce fichier
│
├── profiles/
│   ├── tpu85a/
│   │   └── bambu_a1_0.4mm.json        ← profil OrcaSlicer validé
│   ├── tpu98a/
│   │   └── bambu_a1_0.4mm.json        ← profil OrcaSlicer à valider
│   └── tpu70d/
│       └── template.json              ← profil à remplir post-DOE
│
├── macros/
│   └── klipper/
│       ├── tpu85a_start.cfg
│       ├── tpu98a_start.cfg
│       └── print_end_tpu.cfg          ← macro fin universelle
│
└── rex/
    ├── REX_TPU85A_NinjaFlex_BambuA1_0.4mm_229C_v2.html   ← existant ✅
    └── DOE_TPU70D_L8_template.xlsx    ← à créer
```

### Intégration Notion
- Base de données : **Macros GCODE** (workspace ⚙️ OS)
- Tags : Matière / Machine / Statut (validé / à tester / en cours)
- Champs : lien GitHub (fichier direct) + lien REX + date dernière validation

---

## Suivi

| Tâche | Phase | Statut |
|-------|-------|--------|
| REX TPU 85A NinjaFlex Bambu A1 | 1 | ✅ validé |
| Fiche TPU 98A | 1 | ⬜ à créer |
| Fiche TPU 70D Recreus | 1 | ⬜ à qualifier (DOE) |
| Macro Klipper TPU 85A | 2 | ⬜ à écrire |
| Macro Klipper TPU 98A | 2 | ⬜ à écrire |
| Profil JSON OrcaSlicer TPU 85A | 2 | ⬜ à exporter |
| Profil JSON OrcaSlicer TPU 98A | 2 | ⬜ à créer |
| Restructuration repo | 3 | ⬜ à faire |
| Intégration Notion Macros GCODE | 3 | ⬜ à faire |
| DOE Taguchi L8 TPU 70D | 3 | ⬜ à planifier |
