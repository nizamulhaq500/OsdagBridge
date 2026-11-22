import pytest
import numpy as np
import xarray as xr
from PySide6.QtWidgets import QApplication

from osdagbridge.core.bridge_types.plate_girder.results_data import get_transverse_member_tags
from osdagbridge.core.bridge_types.plate_girder.plot_generator import (
    _find_transverse_lines,
    _build_transverse_polyline,
    _build_transverse_deflection_polyline,
    build_figure_sfd,
    build_figure_bmd,
    build_figure_deflection,
    build_figure_grillage
)
from osdagbridge.desktop.ui.docks.output_dock import OutputDock

@pytest.fixture(scope="session")
def qapp():
    app = QApplication.instance()
    if app is None:
        app = QApplication([])
    return app

def create_synthetic_bridge_model():
    """
    Creates a simple 2-girder grillage model with 3 transverse lines:
    G1 at z=0.0: nodes 1 (x=0), 2 (x=10), 3 (x=20)
    G2 at z=2.5: nodes 4 (x=0), 5 (x=10), 6 (x=20)
    Longitudinal elements:
      101: 1 -> 2 (z=0)
      102: 2 -> 3 (z=0)
      103: 4 -> 5 (z=2.5)
      104: 5 -> 6 (z=2.5)
    Transverse elements:
      201: 1 -> 4 (x=0, End Diaphragm 1)
      202: 2 -> 5 (x=10, Cross Bracing 1)
      203: 3 -> 6 (x=20, End Diaphragm 2)
    """
    nodes = {
        1: [0.0, 0.0, 0.0],
        2: [10.0, 0.0, 0.0],
        3: [20.0, 0.0, 0.0],
        4: [0.0, 0.0, 2.5],
        5: [10.0, 0.0, 2.5],
        6: [20.0, 0.0, 2.5],
    }
    members = {
        101: [1, 2],
        102: [2, 3],
        103: [4, 5],
        104: [5, 6],
        201: [1, 4],
        202: [2, 5],
        203: [3, 6],
    }

    elem_ids = list(members.keys())
    node_ids = list(nodes.keys())
    components = [
        "Vx_i", "Vx_j", "Vy_i", "Vy_j", "Vz_i", "Vz_j",
        "Mx_i", "Mx_j", "My_i", "My_j", "Mz_i", "Mz_j"
    ]
    # Forces in N (will be divided by 1000 in plot_generator to kN / kNm)
    force_vals = np.ones((len(elem_ids), len(components))) * 15000.0
    da_forces = xr.DataArray(
        force_vals,
        coords={"Element": elem_ids, "Component": components},
        dims=["Element", "Component"]
    )

    disp_components = ["dx", "dy", "dz"]
    # Displacements in m (will be converted to mm in deflection diagram)
    disp_vals = np.ones((len(node_ids), len(disp_components))) * -0.015
    da_disp = xr.DataArray(
        disp_vals,
        coords={"Node": node_ids, "Component": disp_components},
        dims=["Node", "Component"]
    )

    ds = xr.Dataset({
        "forces": da_forces,
        "displacements": da_disp
    })

    return nodes, members, ds

def test_get_transverse_member_tags():
    nodes, members, _ = create_synthetic_bridge_model()
    raw_data = {
        "nodes": nodes,
        "members": members
    }
    trans_tags = get_transverse_member_tags(raw_data)
    # Elements 201, 202, 203 connect nodes across different z coordinates
    assert set(trans_tags) == {201, 202, 203}
    assert 101 not in trans_tags
    assert 102 not in trans_tags

def test_find_transverse_lines():
    nodes, members, _ = create_synthetic_bridge_model()
    trans_lines = _find_transverse_lines(nodes, members)
    
    assert "End Diaphragm 1" in trans_lines
    assert "Cross Bracing 1" in trans_lines
    assert "End Diaphragm 2" in trans_lines

    assert trans_lines["End Diaphragm 1"] == [201]
    assert trans_lines["Cross Bracing 1"] == [202]
    assert trans_lines["End Diaphragm 2"] == [203]

def test_build_transverse_polyline():
    nodes, members, ds = create_synthetic_bridge_model()
    xs, ys, zs, V, node_ids = _build_transverse_polyline(
        [201], members, nodes, "Vy_i", "Vy_j", ds
    )
    assert len(xs) == 2
    assert xs[0] == pytest.approx(0.0)
    assert xs[1] == pytest.approx(0.0)
    assert zs[0] == pytest.approx(0.0)
    assert zs[1] == pytest.approx(2.5)
    # 15000 N / 1000 = 15 kN
    assert V[0] == pytest.approx(15.0)
    assert V[1] == pytest.approx(15.0)

def test_build_transverse_deflection_polyline():
    nodes, members, ds = create_synthetic_bridge_model()
    disp_dict = {1: -15.0, 4: -15.0}
    xs, ys, zs, vals, node_ids = _build_transverse_deflection_polyline(
        [201], members, nodes, disp_dict
    )
    assert len(vals) == 2
    assert vals[0] == pytest.approx(-15.0)
    assert vals[1] == pytest.approx(-15.0)

def test_output_dock_contains_transverse_members(qapp):
    from osdagbridge.core.utils.common import KEY_ANALYSIS_MEMBER
    from osdagbridge.core.bridge_types.plate_girder.plategirderbridge import PlateGirderBridge
    backend = PlateGirderBridge()
    dock = OutputDock(backend=backend)
    dock.refresh_member_dropdown()
    combo_analysis = dock._w(KEY_ANALYSIS_MEMBER)
    assert combo_analysis is not None
    all_items = [combo_analysis.itemText(i) for i in range(combo_analysis.count())]
    assert "Transverse Members" in all_items
    assert "All" in all_items

def test_build_figure_sfd_transverse_members():
    nodes, members, ds = create_synthetic_bridge_model()
    fig, summary = build_figure_sfd(ds, "Fy", nodes, members, selected_girder="Transverse Members")
    assert fig is not None
    assert "Transverse Members" in summary
    assert "End Diaphragm 1" in summary

def test_build_figure_bmd_transverse_members():
    nodes, members, ds = create_synthetic_bridge_model()
    fig, summary = build_figure_bmd(ds, "Mz", nodes, members, selected_girder="Transverse Members")
    assert fig is not None
    assert "Transverse Members" in summary
    assert "Cross Bracing 1" in summary

def test_build_figure_deflection_transverse_members():
    nodes, members, ds = create_synthetic_bridge_model()
    fig, summary = build_figure_deflection(ds, "Dy", nodes, members, selected_girder="Transverse Members")
    assert fig is not None
    assert "Transverse Members" in summary

def test_build_figure_grillage_transverse_members():
    nodes, members, _ = create_synthetic_bridge_model()
    fig = build_figure_grillage(nodes, members, selected_girder="Transverse Members")
    assert fig is not None
