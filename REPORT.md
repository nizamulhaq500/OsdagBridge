# OsdagBridge: UI, 2D CAD, and Plotting Enhancements
## Screening Task Technical Report — FOSSEE Internship Submission

**Candidate**: FOSSEE Internship Applicant  
**Target Repository**: [OsdagBridge](https://github.com/Nidhikhare12/OsdagBridge.git)  
**Target Branch**: `dev`  
**Collaborator Invited**: `Nidhikhare12`  

---

### Executive Summary

This report documents the architectural design, mathematical derivations, implementation details, and verification results for the **OsdagBridge UI, 2D CAD, and Plotting Enhancements** screening task. All three required tasks have been implemented strictly following the project's design conventions, utilizing imported constants from `common.py`, adhering to clean architectural separation between GUI and core calculation engines, and verified through a comprehensive automated test suite (17/17 unit tests passing).

The enhancements comprise:
1. **Task I: Interactive 2D CAD Parameter Editing**: Interactive double-click editing on dimension labels in Cross-Section and Top View CAD widgets with mathematical constraints enforcing model consistency.
2. **Task II: Additional Inputs Pre-Save Validation & Modification Tracking**: Robust change detection, active-tab pre-save validation with mandatory error message formatting, critical dialog halts, and unsaved changes confirmation prompts.
3. **Task III: Transverse Member Results Plotting (Cross Bracing / Diaphragms)**: Identification, topological line reconstruction, and 3D visual diagramming (SFD, BMD, Deflection) of transverse bridge elements within the grillage post-processing environment.

---

### 1. Task I: Interactive 2D CAD Parameter Editing

#### 1.1 Objective & UX Architecture
The 2D CAD cross-section and top view drawings serve as the primary visual sanity check for structural engineers configuring highway plate girder bridges. Previously, these drawings were strictly read-only render targets. 

Task I transforms these CAD canvases into interactive editing surfaces:
- **Interactive Dimension Detection**: When the mouse hovers over dimension callouts, the mouse cursor dynamically switches to `Qt.PointingHandCursor`.
- **Inline Floating Editor**: Double-clicking an editable dimension instantiates an in-place floating `QLineEdit` (`#cad_inline_editor`) styled to match the Osdag aesthetic, automatically pre-populated and text-selected.
- **Commit & Abort Lifecycle**: Pressing `Enter` / `Return` or focusing out commits the numeric value; pressing `Escape` cancels without changes.
- **Signal-Driven Upstream Propagation**: Emits a `parameter_edited(str, float)` signal from the canvas through `BridgeDualCADWidget` to `BridgeTemplatePage`.

#### 1.2 Mathematical Derivations & Constraint Rationale
A vital engineering requirement of this task was determining which dimensions should be editable versus which must remain locked. Highway bridge layouts adhere to rigorous geometric relationships defined by IRC:5 and IRC:SP:84.

Let:
- $W_{\text{cw}}$: Carriageway Width (m)
- $S_{\text{girder}}$: Transverse Girder Spacing (m)
- $N_{\text{girders}}$: Number of Longitudinal Girders
- $D_{\text{overhang}}$: Deck Cantilever Overhang (m)
- $W_{\text{overall}}$: Overall Bridge Width (m)
- $L_{\text{span}}$: Total Span Length (m)
- $N_{\text{bracing}}$: Number of Intermediate Cross Bracings
- $S_{\text{bracing}}$: Longitudinal Bracing Spacing (m)

The bridge cross-section is governed by:
$$W_{\text{overall}} = (N_{\text{girders}} - 1) \times S_{\text{girder}} + 2 \times D_{\text{overhang}}$$

The longitudinal layout is governed by:
$$S_{\text{bracing}} = \frac{L_{\text{span}}}{N_{\text{bracing}} + 1}$$

##### Overhang, Overall Width, and Bracing Spacing Must Remain Locked:
1. **Mathematical Over-Determination & Divergence**: 
   If a user were allowed to directly overwrite $W_{\text{overall}}$, the system enters an indeterminate state: should $S_{\text{girder}}$ increase, $D_{\text{overhang}}$ widen, or $N_{\text{girders}}$ increment? Changing $D_{\text{overhang}}$ independently similarly conflicts with standard aerodynamic windward slab cantilever limits.
2. **Topological Invariant in Top View**:
   $S_{\text{bracing}}$ is strictly derived from span length and the integer number of cross bracing panels. Allowing arbitrary floating-point editing of $S_{\text{bracing}}$ directly violates the boundary conditions of the end diaphragms at the bearings ($x = 0$ and $x = L_{\text{span}}$).

##### Dimension Configuration Matrix:
| Parameter | Common Key | View | Status | Rationale |
|---|---|---|---|---|
| Carriageway Width | `KEY_CARRIAGEWAY_WIDTH` | Cross-Section | **Editable** | Independent driver parameter |
| Girder Spacing | `KEY_TS_GIRDER_SPACING` | Cross-Section & Top View | **Editable** | Independent layout parameter |
| Slab Deck Thickness | `KEY_TS_DECK_THICKNESS` | Cross-Section | **Editable** | Independent structural parameter |
| Span Length | `KEY_SPAN` | Top View | **Editable** | Primary bridge geometry driver |
| Deck Overhang | `KEY_TS_DECK_OVERHANG` | Cross-Section | **Locked** | Derived from carriageway width & spacing |
| Overall Bridge Width | `KEY_TS_OVERALL_WIDTH` | Cross-Section | **Locked** | Governed by $(N-1)S + 2D_{\text{overhang}}$ |
| Cross Bracing Spacing | `KEY_MP_CB_SPACING` | Top View | **Locked** | Governed by $L_{\text{span}} / (N_{\text{bracing}} + 1)$ |

When a locked dimension is double-clicked, inline editing is prevented, and an informative, non-blocking `QToolTip` is shown directly at the label:
`"[Parameter Name] is mathematically derived and locked (read-only)."`

#### 1.3 Synchronization with Layout Solver & Input Dock
When an editable dimension is modified in either CAD view:
1. `parameter_edited(key, value)` is emitted.
2. `BridgeDualCADWidget` forwards the signal via `cad_parameter_edited`.
3. `BridgeTemplatePage._on_cad_parameter_edited(key, value)`:
   - Updates `self.input_dict[key] = value`.
   - Synchronizes the corresponding widget in `InputDock` (e.g. `QLineEdit.setText(...)`).
   - Synchronizes any active input fields in the `AdditionalInputs` dialog.
   - Re-runs `BridgeConfigurationSolver._solve_layout(...)` or `solve_extend_basic_input_dict(...)` to maintain model consistency.
   - Pushes updated parameters to CAD widgets and triggers immediate re-rendering.

---

### 2. Task II: Additional Inputs Pre-Save Validation & Modification Tracking

#### 2.1 State Tracking (`is_modified`)
The `AdditionalInputs` dialog holds advanced structural parameters across 7 tabbed categories (Deck Slab, Girder Details, Cross Bracing, End Diaphragms, Bearings, Materials, and Design Options).

To track dirty states accurately without degrading GUI responsiveness:
- An instance flag `self.is_modified = False` is established upon dialog initialization.
- In `set_input_dictionary()`, while initial data is being populated into widgets, change handlers are blocked or `is_modified` is reset to `False` at the end of the load cycle.
- All input widgets across all tabs are wired to `self._mark_modified`:
  - `QLineEdit.textEdited` (distinguishes programmatic `setText` from human keystrokes).
  - `QComboBox.activated` (distinguishes programmatic updates from user dropdown changes).
  - `QCheckBox.clicked` / `QRadioButton.clicked`.

#### 2.2 Pre-Save Validation Protocol (`_validate_custom_fields`)
Whenever standard components (Crash Barrier, Footpath, Railing, Median, Structural Steel) are set to `"Custom"`, child geometric dimension fields are enabled for user entry. 

When the user clicks **Save Inputs**:
1. `_validate_custom_fields()` is triggered prior to persisting changes.
2. The validator scans all active tabs and inspects every field associated with a `"Custom"` parent configuration.
3. If any required custom numeric field is empty or contains only whitespace:
   - Validation halts immediately.
   - An exact error string is constructed:
     $$\text{"Error: The custom value for '}[Parameter Name]\text{' cannot be empty."}$$
   - The user is alerted using `CustomMessageBox(dialogType=MessageBoxType.Critical)`.
   - The dialog remains open on the offending tab, and data is **not saved**.

#### 2.3 Unsaved Changes Discard Guard
If `is_modified` is `True` and the user attempts to close the dialog via:
- Window close button (`X`),
- Pressing `Escape` (rejection), or
- Clicking the **Cancel** button,

`closeEvent(event)` and `reject()` intercept the termination:
- Displays a confirmation `CustomMessageBox(dialogType=MessageBoxType.Warning)`:
  `"You have unsaved changes. Closing this window will discard them. Do you want to proceed?"`
- Options provided: `["Discard", "Cancel"]`.
- Selecting **Discard** dismisses the window and discards changes; selecting **Cancel** preserves window state.

---

### 3. Task III: Transverse Member Results Plotting

#### 3.1 Background & Engineering Motivation
The finite-element grillage method idealizes a slab-on-girder bridge as an orthogonal mesh of beam elements. In OpenSees / `ospgrillage`:
- Longitudinal elements represent composite steel plate girders.
- Transverse elements represent the concrete deck slab strip, end diaphragms, and intermediate steel cross bracings.

While longitudinal girders ($G_1, G_2, \dots, G_n$) carry primary bending and longitudinal shear, transverse members are vital for:
1. Resisting torsional distortion and lateral-torsional buckling (LTB).
2. Distributing heavy eccentric live-load truck axles across adjacent girders.
3. Transferring lateral wind and seismic forces to the substructure bearings.

Prior to this work, result plotting was restricted to longitudinal girders. Task III extends full post-processing visualization to all transverse members.

#### 3.2 Member Classification & Coordinate Filtering
In `ospgrillage`, grillage coordinates are oriented such that:
- $X$: Longitudinal bridge axis (along the span).
- $Y$: Vertical elevation axis.
- $Z$: Transverse bridge axis (across the bridge width).

Longitudinal members connect nodes with identical $Z$ coordinates:
$$|z_1 - z_2| < 10^{-3}\,\text{m}$$

Transverse members connect adjacent longitudinal girders across different $Z$ coordinates:
$$|z_1 - z_2| \ge 10^{-3}\,\text{m}$$

We implemented `get_transverse_member_tags(data: dict) -> list[int]` in `results_data.py` to reliably query and filter all transverse beam tags.

#### 3.3 Topological Line Reconstruction (`_find_transverse_lines`)
Individual transverse beam elements in OpenSees are discretized between adjacent girder lines. To present engineers with meaningful continuous diagrams across the entire bridge deck, we developed a topological graph reconstruction algorithm:
1. Transverse elements are extracted and end nodes indexed.
2. Breadth-First Search (BFS) groups connected collinear elements spanning from the leftmost girder to the rightmost girder.
3. Groups are sorted longitudinally by their mean $X$-coordinate along the span:
   - Line at $X \approx 0$: **End Diaphragm 1** (`ED1`)
   - Intermediate lines at $0 < X < L$: **Cross Bracing 1** (`CB1`), **Cross Bracing 2** (`CB2`), etc.
   - Line at $X \approx L$: **End Diaphragm 2** (`ED2`)
4. Elements within each line are ordered monotonically along $Z$ to form continuous polylines.

#### 3.4 3D Diagram Visualisation Engine
Within `plot_generator.py`, the plotting routines for SFD, BMD, Deflection, and Grillage were enhanced to support `selected_girder == "Transverse Members"`:

- **Shear Force Diagram (SFD - $V_y$)**:
  - Reconstructs stepped force polygons using `np.repeat(..., 2)`.
  - Plots shaded vertical surfaces (`ax.plot_surface`) with `#90CAF9` fill and `#1565C0` outline.
  - Draws vertical drop lines at node locations.
  - Highlights global peak shear values with distinct markers and labels.
- **Bending Moment Diagram (BMD - $M_z$)**:
  - Reconstructs moment variations along each transverse station.
  - Applies negative sign convention to plot positive sagging moments downward.
  - Visualizes moment distributions with `#EF9A9A` fill and `#C62828` boundaries.
  - Displays maximum and minimum moment annotations.
- **Deflection Diagram (Deflection - $D_y$)**:
  - Extracts vertical displacements from `ds["displacements"]` in mm.
  - Renders deflection profiles using `#6A1B9A` curves.
  - Identifies and labels maximum downward sag nodes and uplift locations.
- **3D Spatial Reference & Grillage Integration**:
  - When `"Transverse Members"` is selected, the background grillage structure, bearing supports (pin/roller), and coordinate triad remain visible for context.
  - In `OutputDock`, `"Transverse Members"` is added directly to the Analysis Member dropdown (`combo_analysis`) alongside `"All"` and individual girders.

---

### 4. Verification & Automated Test Suite

A comprehensive test suite of 17 automated tests was implemented and executed via `pytest`. All tests pass cleanly without errors:

```
============================= test session starts ==============================
platform darwin -- Python 3.12.16, pytest-9.2.0, pluggy-1.7.0
rootdir: /Users/nizam/internship/OsdagBridge
configfile: pyproject.toml
collecting ... collecting 17 items                                                            collected 17 items                                                             

tests/unit/test_task1_cad_editing.py ....                                [ 23%]
tests/unit/test_task2_validation.py ....                                 [ 47%]
tests/unit/test_task3_transverse_results.py .........                    [100%]

======================== 17 passed, 3 warnings in 7.35s ========================
```

#### Test Suite Breakdown:

##### Task I: `tests/unit/test_task1_cad_editing.py`
- `test_cross_section_hitboxes_and_editing`: Verifies registration of editable vs. locked hitboxes in cross-section CAD, double-click inline editor launch, and signal emission.
- `test_cross_section_locked_hitbox_blocks_edit`: Verifies that locked parameters (e.g. `KEY_TS_OVERALL_WIDTH`) reject inline editing.
- `test_top_view_hitboxes_and_editing`: Verifies top view dimension hitboxes (span editable, bracing spacing locked) and value commit via `returnPressed`.
- `test_dual_view_signal_forwarding`: Verifies signal forwarding from child cross-section and top view widgets through `BridgeDualCADWidget.cad_parameter_edited`.

##### Task II: `tests/unit/test_task2_validation.py`
- `test_initial_state_not_modified`: Confirms `is_modified` starts as `False` upon input dict loading.
- `test_modification_flag_set_on_edit`: Confirms `is_modified` transitions to `True` upon user edits.
- `test_validate_custom_fields_empty`: Verifies that empty custom fields trigger exact error formatting: `"Error: The custom value for '[Parameter Name]' cannot be empty."`
- `test_validate_custom_fields_valid`: Confirms valid standard/custom configurations pass validation.

##### Task III: `tests/unit/test_task3_transverse_results.py`
- `test_get_transverse_member_tags`: Tests coordinate-based transverse element filtering.
- `test_find_transverse_lines`: Tests topological grouping into End Diaphragms and Cross Bracings.
- `test_build_transverse_polyline`: Tests force array construction and spatial geometry alignment.
- `test_build_transverse_deflection_polyline`: Tests deflection node extraction and integer/string key tolerance.
- `test_output_dock_contains_transverse_members`: Verifies `"Transverse Members"` entry in `OutputDock` dropdown.
- `test_build_figure_sfd_transverse_members`: End-to-end 3D SFD figure generation for transverse members.
- `test_build_figure_bmd_transverse_members`: End-to-end 3D BMD figure generation for transverse members.
- `test_build_figure_deflection_transverse_members`: End-to-end 3D Deflection figure generation for transverse members.
- `test_build_figure_grillage_transverse_members`: End-to-end Grillage highlighting for transverse members.

---

### 5. Summary of Modified Codebase Files

| File Path | Scope of Modification |
|---|---|
| `src/osdagbridge/desktop/ui/docks/cad_cross_section.py` | Added dimension hitboxes, inline `QLineEdit` floating editor, hover cursor feedback, and `parameter_edited` signal. |
| `src/osdagbridge/desktop/ui/docks/cad_top_view.py` | Added dimension hitboxes (span, girder spacing, bracing spacing), inline editor, and `parameter_edited` signal. |
| `src/osdagbridge/desktop/ui/docks/cad_dual_view.py` | Added `cad_parameter_edited` signal forwarding from child CAD widgets. |
| `src/osdagbridge/desktop/ui/template_page.py` | Connected `cad_parameter_edited` to `_on_cad_parameter_edited`, syncing `input_dict`, widgets, and layout solver. |
| `src/osdagbridge/desktop/ui/dialogs/additional_input/additional_inputs.py` | Added `is_modified` tracking, `_validate_custom_fields`, critical halting dialog, and unsaved changes confirmation on close. |
| `src/osdagbridge/core/bridge_types/plate_girder/results_data.py` | Added `get_transverse_member_tags()` helper for transverse element filtering. |
| `src/osdagbridge/desktop/ui/docks/output_dock.py` | Added `"Transverse Members"` to analysis member dropdown in `refresh_member_dropdown()`. |
| `src/osdagbridge/core/bridge_types/plate_girder/plot_generator.py` | Implemented transverse line extraction (`_find_transverse_lines`, `_build_transverse_polyline`) and transverse rendering in SFD, BMD, Deflection, and Grillage. |
| `tests/unit/test_task1_cad_editing.py` | Automated unit tests for Task I interactive CAD editing. |
| `tests/unit/test_task2_validation.py` | Automated unit tests for Task II validation and modification tracking. |
| `tests/unit/test_task3_transverse_results.py` | Automated unit tests for Task III transverse member plotting. |

---

### 6. Video Demonstration Guide & Walkthrough Script (~2 Minutes)

For the unlisted YouTube screencast video submission:

- **0:00 - 0:20 (Introduction & Architecture)**:
  - Introduce OsdagBridge enhancements for UI, 2D CAD, and transverse result plotting.
  - Mention clean architectural alignment with `common.py` constants and automated test coverage.
- **0:20 - 0:50 (Task I: Interactive 2D CAD Editing)**:
  - Demonstrate hovering over dimension labels (cursor changes to pointing hand).
  - Double-click Carriageway Width (7.5 m) in Cross-Section CAD: show floating inline editor. Change to 8.4 m and press Enter. Show that Girder Spacing and overall layout re-solve automatically and update the Input Dock.
  - Double-click Overall Width or Deck Overhang: show the informative tooltip explaining they are mathematically derived and locked.
  - Switch to Top View: double-click Span Length (20 m), update to 25 m, press Enter. Show instantaneous update.
- **0:50 - 1:20 (Task II: Additional Inputs Pre-Save Validation)**:
  - Open **Additional Inputs** dialog.
  - Go to Deck Slab -> set Crash Barrier to "Custom" -> clear Crash Barrier Width.
  - Click **Save Inputs**: show the Critical Message Box: `"Error: The custom value for 'Crash Barrier Width' cannot be empty."` Notice save is halted.
  - Fill in valid value (0.45 m). Modify another field and click `X` / Close without saving.
  - Show warning prompt: `"You have unsaved changes. Closing this window will discard them. Do you want to proceed?"` Show Cancel vs Discard.
- **1:20 - 1:50 (Task III: Transverse Member Result Plotting)**:
  - Show Analysis tab in Output Dock.
  - Open Member selection dropdown: highlight new option **"Transverse Members"**.
  - Select "Transverse Members" and view 3D Sheer Force Diagram (SFD): show stepped diagrams across End Diaphragm 1, Cross Bracings, and End Diaphragm 2.
  - Switch to Bending Moment Diagram (BMD) and Deflection: show 3D profiles along transverse lines with peak annotations.
- **1:50 - 2:05 (Conclusion & Test Suite)**:
  - Run `pytest` in terminal showing 17/17 passed tests.
  - Conclude demonstration.
