#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 2.2cm, right: 2.2cm),
  header: context {
    if here().page() > 1 {
      text(8.5pt, fill: rgb("#64748B"), font: "New Computer Modern")[
        _FOSSEE Screening Task Report — OsdagBridge UI, 2D CAD, & Plotting_
        #h(1fr)
        _November 2026_
      ]
    }
  },
  footer: context {
    align(center, text(8.5pt, fill: rgb("#64748B"), font: "New Computer Modern")[
      Page #counter(page).display("1")
    ])
  }
)

#set text(
  font: "New Computer Modern",
  size: 10pt,
  fill: rgb("#1E293B"),
  lang: "en"
)

#set par(
  justify: true,
  leading: 0.62em
)

#show heading: set text(fill: rgb("#0F172A"))
#show heading.where(level: 1): it => block(above: 1.4em, below: 0.7em)[
  #text(15pt, weight: "bold", fill: rgb("#0F766E"))[#it.body]
  #v(2pt)
  #line(length: 100%, stroke: 0.5pt + rgb("#0F766E"))
]
#show heading.where(level: 2): it => block(above: 1.1em, below: 0.5em)[
  #text(12pt, weight: "bold", fill: rgb("#0369A1"))[#it.body]
]
#show heading.where(level: 3): it => block(above: 0.8em, below: 0.35em)[
  #text(10.5pt, weight: "bold", fill: rgb("#334155"))[#it.body]
]

#show raw.where(block: true): it => block(
  fill: rgb("#F8FAFC"),
  stroke: 0.5pt + rgb("#CBD5E1"),
  inset: 8pt,
  radius: 4pt,
  width: 100%,
  text(8pt, font: "Menlo")[#it]
)

#show raw.where(block: false): it => box(
  fill: rgb("#F1F5F9"),
  inset: (x: 3pt, y: 0pt),
  outset: (y: 2.5pt),
  radius: 2pt,
  text(8.5pt, font: "Menlo", fill: rgb("#BE185D"))[#it]
)

#let passed-badge = box(
  fill: rgb("#DEF7EC"),
  inset: (x: 4pt, y: 2pt),
  radius: 3pt,
  baseline: 0%
)[#text(rgb("#03543F"), weight: "bold", size: 6.5pt)[PASSED]]

#let editable-badge = box(
  fill: rgb("#E0F2FE"),
  inset: (x: 4pt, y: 2pt),
  radius: 3pt,
  baseline: 0%
)[#text(rgb("#0369A1"), weight: "bold", size: 6.5pt)[Editable]]

#let locked-badge = box(
  fill: rgb("#FEF3C7"),
  inset: (x: 4pt, y: 2pt),
  radius: 3pt,
  baseline: 0%
)[#text(rgb("#92400E"), weight: "bold", size: 6.5pt)[Locked]]

// Title Banner
#align(center)[
  #block(width: 100%, stroke: (bottom: 1.5pt + rgb("#0F766E")), inset: (bottom: 12pt))[
    #text(19pt, weight: "bold", fill: rgb("#0F766E"))[OsdagBridge Enhancement Report]
    #v(4pt)
    #text(11.5pt, weight: "medium", fill: rgb("#475569"))[
      Interactive 2D CAD Parameter Editing, Pre-Save Input Validation, and Transverse Member Plotting
    ]
    #v(8pt)
    #text(9.5pt, fill: rgb("#334155"))[
      *FOSSEE Internship Screening Task Submission* \
      *Target Repository:* `https://github.com/Nidhikhare12/OsdagBridge.git` \
      *Target Branch:* `dev` #h(10pt) | #h(10pt) *Reviewer / Collaborator:* `Nidhikhare12`
    ]
  ]
]

#v(6pt)

= Executive Summary

This report presents the complete technical implementation, mathematical derivations, software architecture, and test verification results for the three assigned screening tasks in the *OsdagBridge* highway bridge design suite:

1. *Task I: Interactive 2D CAD Parameter Editing*: Bi-directional parameter editing on cross-section and top view CAD canvases via double-click interactions, backed by a strict mathematical classification distinguishing independent driver dimensions from locked derived parameters.
2. *Task II: Additional Inputs Pre-Save Validation & Modification Tracking*: State-aware dirty flag tracking across seven modal tabs, active tab validation halting on empty custom fields with standard error syntax, and discard confirmation dialogues.
3. *Task III: Transverse Member Results Plotting (Cross Bracing / Diaphragms)*: Identification, topological line reconstruction, and 3D visual diagramming of transverse bridge elements (SFD, BMD, Deflection, and Grillage) within the grillage post-processing framework.

All features strictly employ constants imported from `common.py`, avoid hardcoded parameter strings, and are verified by *17 automated unit tests* passing with a 100% success rate.

= Task I: Interactive 2D CAD Parameter Editing

== Motivation and Interactive UX Design
In highway bridge design workflows, structural engineers continuously cross-reference numerical schedules with geometric diagrams. Previously, the 2D CAD views in OsdagBridge functioned exclusively as static presentation canvases. 

Task I establishes an interactive direct-manipulation interface:
- *Visual Affordance*: Moving the mouse cursor over registered dimension labels changes the cursor dynamically to `Qt.PointingHandCursor`.
- *In-Place Floating Editor*: Double-clicking an editable dimension instantiates an in-place `QLineEdit` overlay directly above the callout text, styled with the application's signature border and typography, automatically focused and pre-selected.
- *Commit Lifecycle*: Pressing `Enter` / `Return` or clicking away commits the numeric input; pressing `Escape` discards edits cleanly.
- *Signal Routing*: The canvas emits a `parameter_edited(key, value)` signal forwarded through `BridgeDualCADWidget` to `BridgeTemplatePage`.

#pagebreak()

== Mathematical Formulations & Derivations
Highway plate girder bridge geometry follows rigid physical and code-mandated relationships (IRC:5, IRC:SP:84). An arbitrary "free edit" model would introduce mathematical over-determination and model divergence. We established a rigorous distinction between *independent drivers* and *dependent derived values*.

Let:
- $W_"cw"$: Carriageway Width (m)
- $S_"girder"$: Transverse Girder Spacing (m)
- $N_"girders"$: Total Number of Longitudinal Girders
- $D_"overhang"$: Deck Cantilever Overhang (m)
- $W_"overall"$: Overall Bridge Deck Width (m)
- $L_"span"$: Total Span Length (m)
- $N_"bracing"$: Number of Intermediate Cross Bracing Panels
- $S_"bracing"$: Longitudinal Bracing Spacing (m)

=== Transverse Cross-Section Governing Equation
The total width of the bridge superstructure is mathematically defined as:
$ W_"overall" = (N_"girders" - 1) times S_"girder" + 2 times D_"overhang" $

=== Longitudinal Bracing Governing Equation
Intermediate cross bracings are placed at uniform intervals between end diaphragms:
$ S_"bracing" = frac(L_"span", N_"bracing" + 1) $

=== Mathematical Rationale for Locked vs. Editable Parameters

1. *Why Overhang ($D_"overhang"$) and Overall Width ($W_"overall"$) Must Remain Locked:* \
   $W_"overall"$ and $D_"overhang"$ are dependent functions of the number of girders and their spacing. If an engineer overwrote $W_"overall"$ directly, the system would become under-constrained: should the software adjust the girder spacing, change the overhang, or increment the girder count? Furthermore, aerodynamic stability under lateral wind load imposes limits on cantilever overhang ratios. Therefore, $W_"overall"$ and $D_"overhang"$ are strictly *locked (read-only)*.
2. *Why Bracing Spacing ($S_"bracing"$) Must Remain Locked:* \
   Bracing spacing in the top view is governed by the total span length and the discrete integer count of bracing bays. An arbitrary floating-point change to $S_"bracing"$ would invalidate the boundary conditions at the support bearings ($x = 0$ and $x = L_"span"$).
3. *Informative Tooltip Guidance:* \
   When a user double-clicks any locked dimension, inline text editing is prevented, and an informative, non-blocking tooltip appears at the label:
   #align(center)[_"[Parameter Name] is mathematically derived and locked (read-only)."_]

#v(6pt)
#text(8pt)[
#table(
  columns: (1.5fr, 2.5fr, 1.2fr, 0.9fr, 2.7fr),
  align: (left, left, center, center, left),
  stroke: 0.5pt + rgb("#CBD5E1"),
  inset: (x: 4pt, y: 3.5pt),
  fill: (x, y) => if y == 0 { rgb("#E2E8F0") } else if calc.even(y) { rgb("#F8FAFC") } else { none },
  [*Parameter Name*], [*Common Identifier Key*], [*CAD View*], [*Status*], [*Engineering Rationale*],
  [Carriageway Width], [`KEY_CARRIAGEWAY_WIDTH`], [Cross-Section], editable-badge, [Primary traffic layout driver],
  [Girder Spacing], [`KEY_TS_GIRDER_SPACING`], [Cross-Sec & Top], editable-badge, [Structural transverse layout driver],
  [Slab Deck Thickness], [`KEY_TS_DECK_THICKNESS`], [Cross-Section], editable-badge, [Slab bending resistance parameter],
  [Span Length], [`KEY_SPAN`], [Top View], editable-badge, [Primary longitudinal span driver],
  [Deck Overhang], [`KEY_TS_DECK_OVERHANG`], [Cross-Section], locked-badge, [Derived from width, girders, spacing],
  [Overall Bridge Width], [`KEY_TS_OVERALL_WIDTH`], [Cross-Section], locked-badge, [Strictly $(N - 1)S + 2D_"overhang"$],
  [Cross Bracing Spacing], [`KEY_MP_CB_SPACING`], [Top View], locked-badge, [Strictly $L_"span" / (N_"bracing" + 1)$],
)
]

#pagebreak()

== Synchronization Pipeline with Layout Solver
When an editable dimension is modified in either CAD view, the update propagates through the application stack:
1. The CAD canvas emits `parameter_edited(key, value)`.
2. `BridgeDualCADWidget` forwards the event via `cad_parameter_edited`.
3. `BridgeTemplatePage._on_cad_parameter_edited(key, value)` intercepts the signal:
   - Updates `self.input_dict[key] = value`.
   - Synchronizes the corresponding input field in `InputDock` (e.g. updating the numerical entry box).
   - Re-runs the bridge configuration solver (`solve_extend_basic_input_dict` and `BridgeConfigurationSolver._solve_layout`).
   - Pushes newly derived dimensions back to the CAD widgets and schedules an immediate redraw.

= Task II: Additional Inputs Pre-Save Validation & Modification Tracking

== State-Aware Modification Tracking (`is_modified`)
The `AdditionalInputs` dialogue manages detailed structural properties across seven tabbed modules (Deck Slab, Girder Details, Cross Bracing, End Diaphragms, Bearings, Materials, and Design Options).

To track unsaved changes accurately:
- A boolean flag `self.is_modified = False` is initialized on dialogue creation.
- During initial population in `set_input_dictionary()`, change signals are blocked or the flag is reset to `False` once values are loaded.
- All input widgets across all tabs are bound to `self._mark_modified`:
  - `QLineEdit.textEdited` (fires only on actual user keystrokes, ignoring programmatic assignments).
  - `QComboBox.activated` (fires only on deliberate user selection).
  - `QCheckBox.clicked` and `QRadioButton.clicked`.

== Pre-Save Active Tab Validation (`_validate_custom_fields`)
Whenever standard components (such as Crash Barrier, Footpath, Railing, or Median) are configured as `"Custom"`, geometric input fields become editable.

When the user clicks *Save Inputs*:
1. `_validate_custom_fields()` scans the active tab.
2. Every visible, enabled input associated with a custom component is validated.
3. If any field is empty or contains only whitespace:
   - Save execution is immediately halted.
   - An exact error string is constructed:
     #align(center)[#box(fill: rgb("#FEE2E2"), inset: (x: 8pt, y: 4pt), radius: 3pt)[#text(rgb("#991B1B"), font: "Menlo", size: 8pt)[Error: The custom value for '[Parameter Name]' cannot be empty.]]]
   - A modal critical error dialogue (`CustomMessageBox(dialogType=MessageBoxType.Critical)`) is displayed to the user.
   - The dialogue remains open on the tab so the engineer can correct the value without data loss.

== Discard Confirmation Prompt
If `is_modified` is `True` and the user attempts to close the dialogue via the window `X` button, the `Cancel` button, or the `Escape` key, `closeEvent()` and `reject()` intercept the event:
- A confirmation warning is displayed:
  #align(center)[#box(fill: rgb("#FEF3C7"), inset: (x: 8pt, y: 4pt), radius: 3pt)[#text(rgb("#92400E"), font: "Menlo", size: 8pt)[You have unsaved changes. Closing this window will discard them. Do you want to proceed?]]]
- Action choices: `["Discard", "Cancel"]`.
- Selecting *Discard* closes the dialogue without saving; selecting *Cancel* resumes editing.

#pagebreak()

= Task III: Result Plotting for Transverse Members

== Theoretical Background & Engineering Context
The grillage analogy (Hambly, 1991) discretizes a continuous bridge deck into an equivalent gridwork of beam elements. In OpenSees and `ospgrillage`:
- Longitudinal members model composite steel plate girders.
- Transverse members model the concrete slab strips, steel end diaphragms, and cross bracings.

While longitudinal girders resist global longitudinal bending and shear, transverse members fulfill vital structural functions:
- Distributing concentrated wheel loads transversely across adjacent girders.
- Restraining top and bottom flanges against lateral-torsional buckling (LTB).
- Transferring lateral wind, seismic, and centrifugal loads to the substructure bearings.

Previously, result visualization was limited to longitudinal girders ($G_1, G_2, dots, G_n$). Task III extends 3D visualization to all transverse lines.

== Element Classification and Coordinate Filtering
In `ospgrillage`, grillage coordinate axes are arranged as follows:
- $X$: Longitudinal span axis ($0 <= x <= L_"span"$).
- $Y$: Vertical elevation axis.
- $Z$: Transverse width axis ($0 <= z <= W_"overall"$).

Longitudinal members join nodes possessing identical transverse coordinates:
$ |z_1 - z_2| < 10^(-3) "m" $

Transverse members join adjacent girders across differing transverse coordinates:
$ |z_1 - z_2| >= 10^(-3) "m" $

We implemented `get_transverse_member_tags(data: dict) -> list[int]` in `results_data.py` to reliably query and filter all transverse beam tags.

== Topological Line Reconstruction (`_find_transverse_lines`)
Individual transverse finite elements in OpenSees span between two adjacent girders. To present engineers with unified force diagrams across the full deck width, we developed a topological line grouping algorithm:
1. Transverse element end-nodes are indexed into an adjacency graph.
2. Connected collinear segments spanning from the first girder to the last are grouped into complete transverse lines.
3. Groups are sorted by longitudinal station ($X$-coordinate):
   - At $X approx 0$: *End Diaphragm 1* (`ED1`)
   - At intermediate stations $0 < X < L$: *Cross Bracing 1* (`CB1`), *Cross Bracing 2* (`CB2`), etc.
   - At $X approx L_"span"$: *End Diaphragm 2* (`ED2`)
4. Elements within each line are ordered monotonically along $Z$ to produce continuous polyline data structures.

#pagebreak()

== 3D Diagram Visualisation Engine
Within `plot_generator.py`, the plotting routines for SFD, BMD, Deflection, and Grillage were enhanced to support `selected_girder == "Transverse Members"`:

- *Shear Force Diagram (SFD - $V_y$)*: \
  Reconstructs stepped force polygons using duplicated coordinates `np.repeat(..., 2)`. Renders semi-transparent vertical fill surfaces (`#90CAF9`) and blue boundary lines (`#1565C0`), with vertical drop lines at nodal stations and peak values highlighted.
- *Bending Moment Diagram (BMD - $M_z$)*: \
  Renders continuous transverse moment distributions with coral fill surfaces (`#EF9A9A`) and crimson boundary curves (`#C62828`). Positive sagging moments plot downward in accordance with civil engineering conventions.
- *Deflection Diagram (Deflection - $D_y$)*: \
  Extracts vertical displacements in millimeters, rendering clean purple deflection curves (`#6A1B9A`) with maximum sag and uplift annotations.
- *Spatial Context & UI Integration*: \
  Support bearings (pinned green diamonds, roller yellow circles), coordinate triads, and the background structural grid remain visible for spatial context. `"Transverse Members"` is added directly to the Analysis Member dropdown (`combo_analysis`) in `OutputDock`.

#v(6pt)

#text(8pt)[
#table(
  columns: (1.5fr, 1.8fr, 1.2fr, 3.5fr),
  align: (left, left, center, left),
  stroke: 0.5pt + rgb("#CBD5E1"),
  inset: (x: 4pt, y: 3.5pt),
  fill: (x, y) => if y == 0 { rgb("#E2E8F0") } else if calc.even(y) { rgb("#F8FAFC") } else { none },
  [*Diagram Type*], [*Primary Variable*], [*Plot Color*], [*Visual Rendering Method*],
  [Shear Force (SFD)], [Vertical Shear ($V_y$)], [Cobalt / Sky], [Stepped polygons with `np.repeat`, vertical drop lines],
  [Bending Moment (BMD)], [Major Moment ($M_z$)], [Crimson / Coral], [Continuous smooth polygons, sagging downward (IRC standard)],
  [Deflection], [Displacement ($D_y$)], [Royal Purple], [Continuous 3D space curves, sag/uplift extrema labeled],
  [Grillage Network], [Member Geometry], [Accent Yellow], [Transverse line highlighting against faded grillage grid],
)
]

#pagebreak()

= Verification & Automated Test Suite

A comprehensive test suite containing *17 unit tests* was developed to verify all three tasks. The entire suite passes cleanly without errors:

```
============================= test session starts ==============================
platform darwin -- Python 3.12.16, pytest-9.2.0, pluggy-1.7.0
rootdir: /Users/nizam/internship/OsdagBridge
configfile: pyproject.toml
collecting ... collected 17 items                                                            

tests/unit/test_task1_cad_editing.py ....                                [ 23%]
tests/unit/test_task2_validation.py ....                                 [ 47%]
tests/unit/test_task3_transverse_results.py .........                    [100%]

======================== 17 passed, 3 warnings in 7.35s ========================
```

#v(4pt)

#text(7pt)[
#show raw.where(block: false): it => box(
  fill: rgb("#F1F5F9"),
  inset: (x: 2pt, y: 0pt),
  outset: (y: 1.5pt),
  radius: 2pt,
  text(6.2pt, font: "Menlo", fill: rgb("#BE185D"))[#it]
)
#table(
  columns: (1.1fr, 3.5fr, 0.9fr, 3.1fr),
  align: (left, left, center, left),
  stroke: 0.5pt + rgb("#CBD5E1"),
  inset: (x: 4pt, y: 2.5pt),
  fill: (x, y) => if y == 0 { rgb("#E2E8F0") } else if calc.even(y) { rgb("#F8FAFC") } else { none },
  [*Test Suite*], [*Test Function Name*], [*Status*], [*Validation Scope*],
  [Task I: CAD Editing], [`test_cross_section_hitboxes`], passed-badge, [Hitbox discovery, inline QLineEdit, signal dispatch],
  [Task I: CAD Editing], [`test_cross_section_locked_hitbox`], passed-badge, [Derived dimension locking and tooltip prevention],
  [Task I: CAD Editing], [`test_top_view_hitboxes`], passed-badge, [Span editable, bracing locked, Enter key commit],
  [Task I: CAD Editing], [`test_dual_view_signal_forwarding`], passed-badge, [Signal propagation from children through dual view],
  [Task II: Validation], [`test_initial_state_not_modified`], passed-badge, [Clean initial state upon loading model inputs],
  [Task II: Validation], [`test_modification_flag_set_on_edit`], passed-badge, [Dirty flag toggled on text/combo user interaction],
  [Task II: Validation], [`test_validate_custom_fields_empty`], passed-badge, [Halts save with exact required syntax error string],
  [Task II: Validation], [`test_validate_custom_fields_valid`], passed-badge, [Allows save when custom parameters are valid],
  [Task III: Transverse], [`test_get_transverse_member_tags`], passed-badge, [Filters transverse elements by coordinate tolerance],
  [Task III: Transverse], [`test_find_transverse_lines`], passed-badge, [Groups and labels ED1, Cross Bracings, and ED2],
  [Task III: Transverse], [`test_build_transverse_polyline`], passed-badge, [Builds 3D spatial polyline and force arrays],
  [Task III: Transverse], [`test_build_transverse_deflection`], passed-badge, [Extracts node displacements in millimeters],
  [Task III: Transverse], [`test_output_dock_dropdown`], passed-badge, [Verifies "Transverse Members" in Analysis dropdown],
  [Task III: Transverse], [`test_build_figure_sfd_transverse`], passed-badge, [Generates 3D SFD figure for transverse lines],
  [Task III: Transverse], [`test_build_figure_bmd_transverse`], passed-badge, [Generates 3D BMD figure for transverse lines],
  [Task III: Transverse], [`test_build_figure_deflection`], passed-badge, [Generates 3D Deflection figure for transverse lines],
  [Task III: Transverse], [`test_build_figure_grillage`], passed-badge, [Highlights transverse lines in grillage viewer],
)
]

#pagebreak()

= Video Screencast Demonstration Script (~2 Minutes)

For the required unlisted YouTube screencast video submission:

- *0:00 - 0:20 (Introduction)*: \
  Briefly introduce yourself, the project, and state that Tasks I, II, and III have been implemented and verified with automated tests.
- *0:20 - 0:50 (Task I: Interactive 2D CAD Editing)*: \
  Hover over dimension labels in the cross-section CAD view to demonstrate cursor changes to `PointingHandCursor`. Double-click Carriageway Width (7.5 m) to open the inline floating editor, update to 8.4 m, and press Enter. Point out that the girder layout re-solves and updates the Input Dock automatically. Double-click Overall Width to show the tooltip explaining that it is derived and locked. Switch to Top View, double-click Span Length, update to 25 m, and press Enter.
- *0:50 - 1:20 (Task II: Pre-Save Validation & Confirmation Prompt)*: \
  Open the *Additional Inputs* dialogue, navigate to the Deck Slab tab, switch Crash Barrier to "Custom", and clear the Crash Barrier Width field. Click *Save Inputs* to show the critical error dialogue:
  #align(center)[#box(fill: rgb("#FEE2E2"), inset: (x: 6pt, y: 3pt), radius: 3pt)[#text(rgb("#991B1B"), font: "Menlo", size: 7.5pt)[Error: The custom value for 'Crash Barrier Width' cannot be empty.]]]
  Restore a valid value (0.45 m), edit another field, and click the window's close button without saving to demonstrate the discard confirmation prompt:
  #align(center)[#box(fill: rgb("#FEF3C7"), inset: (x: 6pt, y: 3pt), radius: 3pt)[#text(rgb("#92400E"), font: "Menlo", size: 7.5pt)[You have unsaved changes. Closing this window will discard them. Do you want to proceed?]]]
- *1:20 - 1:50 (Task III: Transverse Member Results Plotting)*: \
  Navigate to the Output Dock Analysis tab. Open the Member selection dropdown and highlight the new option: `"Transverse Members"`. Cycle through the 3D views (SFD, BMD, and Deflection) to showcase stepped shear polygons, moment distributions, and vertical deflection profiles across End Diaphragm 1, Cross Bracings, and End Diaphragm 2.
- *1:50 - 2:05 (Conclusion)*: \
  Switch to the terminal and run `pytest tests/unit/` demonstrating that all 17 unit tests pass. Conclude the demonstration.
