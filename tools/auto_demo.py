"""Automated demonstration runner for OsdagBridge FOSSEE screening task.
Candidate: Nizam (nizamulhaq500)
"""

import sys
import os
import time
import numpy as np
import xarray as xr

from PySide6.QtWidgets import QApplication, QLineEdit, QComboBox, QMessageBox, QToolTip
from PySide6.QtCore import Qt, QTimer, QPoint, QEvent
from PySide6.QtGui import QMouseEvent

# Set Qt plugin path
conda_prefix = sys.prefix
qt_plugin = os.path.join(conda_prefix, "lib", "python3.12", "site-packages", "PySide6", "Qt", "plugins")
if os.path.exists(qt_plugin):
    os.environ["QT_PLUGIN_PATH"] = qt_plugin

from osdagbridge.desktop.ui.template_page import CustomWindow
from osdagbridge.core.bridge_types.plate_girder.plategirderbridge import PlateGirderBridge
from osdagbridge.core.bridge_types.plate_girder.defaults import solve_extend_basic_input_dict
from osdagbridge.core.utils.common import (
    KEY_SPAN, KEY_CARRIAGEWAY_WIDTH, KEY_TS_GIRDER_SPACING,
    KEY_TS_DECK_OVERHANG, KEY_TS_OVERALL_WIDTH, KEY_MP_CB_SPACING,
    KEY_CB_TYPE, KEY_CB_WIDTH, KEY_ANALYSIS_MEMBER, KEY_ANALYSIS_FORCES
)
from osdagbridge.desktop.ui.utils.custom_widgets import CustomRadioButton
from osdagbridge.desktop.ui.dialogs.custom_messagebox import CustomMessageBox

def create_demo_grillage_results():
    nodes = {
        1: [0.0, 0.0, 0.0],
        2: [10.0, 0.0, 0.0],
        3: [20.0, 0.0, 0.0],
        4: [0.0, 0.0, 2.5],
        5: [10.0, 0.0, 2.5],
        6: [20.0, 0.0, 2.5],
        7: [0.0, 0.0, 5.0],
        8: [10.0, 0.0, 5.0],
        9: [20.0, 0.0, 5.0],
    }
    members = {
        101: [1, 2], 102: [2, 3],
        103: [4, 5], 104: [5, 6],
        105: [7, 8], 106: [8, 9],
        201: [1, 4], 202: [4, 7],   # ED1
        203: [2, 5], 204: [5, 8],   # CB1
        205: [3, 6], 206: [6, 9],   # ED2
    }
    elem_ids = list(members.keys())
    node_ids = list(nodes.keys())
    components = [
        "Vx_i", "Vx_j", "Vy_i", "Vy_j", "Vz_i", "Vz_j",
        "Mx_i", "Mx_j", "My_i", "My_j", "Mz_i", "Mz_j"
    ]
    loadcases = ["Envelope", "DL"]
    force_vals = np.ones((len(loadcases), len(elem_ids), len(components))) * 25000.0
    da_forces = xr.DataArray(
        force_vals,
        coords={"Loadcase": loadcases, "Element": elem_ids, "Component": components},
        dims=["Loadcase", "Element", "Component"]
    )
    disp_components = ["dx", "dy", "dz", "x", "y", "z"]
    disp_vals = np.ones((len(loadcases), len(node_ids), len(disp_components))) * -0.018
    da_disp = xr.DataArray(
        disp_vals,
        coords={"Loadcase": loadcases, "Node": node_ids, "Component": disp_components},
        dims=["Loadcase", "Node", "Component"]
    )
    ds_all = xr.Dataset({"forces": da_forces, "displacements": da_disp})
    return ds_all, loadcases, nodes, members

class AutoDemoController:
    def __init__(self, window: CustomWindow):
        self.win = window
        self.step = 0
        self.timer = QTimer()
        self.timer.timeout.connect(self.next_action)

        # Initialize input dictionary with valid values
        self.win.input_dict[KEY_SPAN] = 20.0
        self.win.input_dict[KEY_CARRIAGEWAY_WIDTH] = 7.5
        solve_extend_basic_input_dict(self.win.input_dict)
        self.win.cad_comp_widget.update_from_osdag_inputs(self.win.input_dict)

        # Pre-wire backend and 3D plots widget
        self.win.output_dock.backend = PlateGirderBridge()
        self.win.output_dock.backend.input_dict = self.win.input_dict
        self.win.output_dock.refresh_member_dropdown()

        ds_all, loadcases, nodes, members = create_demo_grillage_results()
        self.win.plots_widget.setup(ds_all, loadcases, nodes, members, edge_dist=1.05)
        self.win.plots_widget.link_output_dock(self.win.output_dock)

        # Start execution after 3 seconds
        QTimer.singleShot(3000, self.start)

    def start(self):
        print("[DEMO] Starting automated UI playback...")
        self.timer.start(1000)

    def next_action(self):
        self.step += 1
        s = self.step
        print(f"[DEMO] t={s}s | Step {s}")

        # --- TASK I: 2D CAD Direct Editing (0 - 45s) ---
        if s == 5:
            # Highlight / hover Carriageway Width
            print("[DEMO] Action: Hovering over Carriageway Width (7.5m)")
            cs = self.win.cad_comp_widget.cross_section_widget
            hb = next((h for h in cs.dimension_label_hitboxes if h["key"] == KEY_CARRIAGEWAY_WIDTH), None)
            if hb:
                center = hb["rect"].center().toPoint()
                QToolTip.showText(cs.mapToGlobal(center), "Double click to edit Carriageway Width", cs, hb["draw_rect"].toRect(), 3000)

        elif s == 9:
            # Double click Carriageway Width -> opens inline editor
            print("[DEMO] Action: Opening inline editor for Carriageway Width")
            cs = self.win.cad_comp_widget.cross_section_widget
            hb = next((h for h in cs.dimension_label_hitboxes if h["key"] == KEY_CARRIAGEWAY_WIDTH), None)
            if hb:
                cs._start_inline_editor(hb)

        elif s == 15:
            # Commit 8.4m in inline editor
            print("[DEMO] Action: Committing 8.4 in inline editor")
            cs = self.win.cad_comp_widget.cross_section_widget
            if cs._active_editor and cs._active_editor.isVisible():
                cs._active_editor.setText("8.4")
                cs._active_editor.returnPressed.emit()

        elif s == 23:
            # Double click Overall Width (locked derived dimension)
            print("[DEMO] Action: Double clicking locked Overall Width")
            cs = self.win.cad_comp_widget.cross_section_widget
            hb = next((h for h in cs.dimension_label_hitboxes if h["key"] == KEY_TS_OVERALL_WIDTH), None)
            if hb:
                tip = f"{hb['name']} is mathematically derived and locked (read-only)."
                center = hb["rect"].center().toPoint()
                QToolTip.showText(cs.mapToGlobal(center), tip, cs, hb["draw_rect"].toRect(), 4000)

        elif s == 31:
            # Switch to Top View CAD
            print("[DEMO] Action: Switching to Top View")
            self.win.top_view_toggle()

        elif s == 37:
            # Double click Span Length in Top View (20.0m)
            print("[DEMO] Action: Double clicking Span Length in Top View")
            tv = self.win.cad_comp_widget.top_view_widget
            hb = next((h for h in tv.dimension_label_hitboxes if h["key"] == KEY_SPAN), None)
            if hb:
                tv._start_inline_editor(hb)

        elif s == 44:
            # Close inline editor and switch back to dual view
            tv = self.win.cad_comp_widget.top_view_widget
            if tv._active_editor and tv._active_editor.isVisible():
                tv._active_editor.hide()
                tv._active_editor = None
            self.win.cross_section_view_toggle()

        # --- TASK II: Additional Inputs Pre-Save Validation (48s - 85s) ---
        elif s == 48:
            # Open Additional Inputs dialog
            print("[DEMO] Action: Opening Additional Inputs dialog")
            self.win._show_additional_inputs(target_tab="Deck Slab")

        elif s == 54:
            # Select Custom for Crash Barrier
            print("[DEMO] Action: Selecting Custom Crash Barrier")
            dlg = self.win._get_additional_inputs()
            cb_combo = dlg.findChild(QComboBox, KEY_CB_TYPE)
            if cb_combo:
                idx = cb_combo.findText("Custom")
                if idx >= 0:
                    cb_combo.setCurrentIndex(idx)
                    cb_combo.activated.emit(idx)

        elif s == 60:
            # Clear width field
            print("[DEMO] Action: Clearing Crash Barrier Width field")
            dlg = self.win._get_additional_inputs()
            cb_width = dlg.findChild(QLineEdit, KEY_CB_WIDTH)
            if cb_width:
                cb_width.setText("")
                cb_width.textEdited.emit("")

        elif s == 65:
            # Click Save Inputs -> Triggers Critical Error Dialog
            print("[DEMO] Action: Clicking Save Inputs to demonstrate Error Dialog")
            dlg = self.win._get_additional_inputs()

            def dismiss_error_modal():
                for w in QApplication.topLevelWidgets():
                    if isinstance(w, CustomMessageBox) and w.isVisible():
                        print(f"[DEMO] Auto-dismissing error dialog: {w.titleBar.title_label.text()}")
                        w.buttonClicked("OK")
                        return

            QTimer.singleShot(6000, dismiss_error_modal)
            dlg.save_button.click()

        elif s == 73:
            # Restore valid value and mark modified
            print("[DEMO] Action: Restoring valid value 0.45m")
            dlg = self.win._get_additional_inputs()
            cb_width = dlg.findChild(QLineEdit, KEY_CB_WIDTH)
            if cb_width:
                cb_width.setText("0.45")
                cb_width.textEdited.emit("0.45")

        elif s == 78:
            # Close window without saving -> Triggers Discard Prompt
            print("[DEMO] Action: Closing window without saving (Discard prompt)")
            dlg = self.win._get_additional_inputs()

            def confirm_discard_modal():
                for w in QApplication.topLevelWidgets():
                    if isinstance(w, CustomMessageBox) and w.isVisible():
                        print(f"[DEMO] Auto-confirming Discard on: {w.titleBar.title_label.text()}")
                        w.buttonClicked("Discard")
                        return

            QTimer.singleShot(5000, confirm_discard_modal)
            dlg.close()

        # --- TASK III: Transverse Member Results Plotting (88s - 120s) ---
        elif s == 88:
            # Open Output Dock if hidden
            print("[DEMO] Action: Ensuring Output Dock is visible")
            if not self.win.output_dock.isVisible():
                self.win.output_dock_toggle()

        elif s == 92:
            # Select Transverse Members in Output Dock
            print("[DEMO] Action: Selecting 'Transverse Members' in Output Dock")
            combo = self.win.output_dock._w(KEY_ANALYSIS_MEMBER)
            if combo:
                idx = combo.findText("Transverse Members")
                if idx >= 0:
                    combo.setCurrentIndex(idx)
                    combo.activated.emit(idx)

        elif s == 96:
            # Switch to 3D Plots View (SFD)
            print("[DEMO] Action: Showing 3D Shear Force Diagram (SFD)")
            self.win.plots_view_toggle()

        elif s == 104:
            # Switch to Bending Moment (BMD)
            print("[DEMO] Action: Switching to Bending Moment Diagram (BMD)")
            for rb in self.win.output_dock.output_widget.findChildren(CustomRadioButton):
                if "M<sub>z</sub>" in rb.text():
                    rb.setChecked(True)
                    break

        elif s == 112:
            # Switch to Deflection
            print("[DEMO] Action: Switching to Deflection Diagram")
            for rb in self.win.output_dock.output_widget.findChildren(CustomRadioButton):
                if "D<sub>y</sub>" in rb.text():
                    rb.setChecked(True)
                    break

        elif s >= 122:
            print("[DEMO] Playback finished. Exiting cleanly.")
            self.timer.stop()
            self.win.close()
            QApplication.quit()

def main():
    app = QApplication(sys.argv)
    from osdagbridge.desktop.__main__ import load_stylesheet
    ss = load_stylesheet()
    if ss:
        app.setStyleSheet(ss)

    win = CustomWindow("OsdagBridge - FOSSEE Screening Task Demo (Nizam)", PlateGirderBridge)
    win.showMaximized()
    win.show()

    runner = AutoDemoController(win)
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
