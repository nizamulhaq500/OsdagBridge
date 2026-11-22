import pytest
from PySide6.QtWidgets import QApplication, QLineEdit
from PySide6.QtCore import Qt, QPoint, QEvent
from PySide6.QtGui import QMouseEvent, QPixmap, QPainter

from osdagbridge.desktop.ui.docks.cad_cross_section import CrossSectionCADWidget
from osdagbridge.desktop.ui.docks.cad_top_view import TopViewCADWidget
from osdagbridge.desktop.ui.docks.cad_dual_view import BridgeDualCADWidget
from osdagbridge.core.bridge_types.plate_girder.defaults import BASIC_INPUT_DICT, solve_extend_basic_input_dict
from osdagbridge.core.utils.common import (
    KEY_SPAN, KEY_CARRIAGEWAY_WIDTH, KEY_TS_GIRDER_SPACING,
    KEY_TS_DECK_THICKNESS, KEY_TS_DECK_OVERHANG, KEY_TS_OVERALL_WIDTH, KEY_MP_CB_SPACING
)

@pytest.fixture(scope="session")
def qapp():
    app = QApplication.instance()
    if app is None:
        app = QApplication([])
    return app

def get_populated_input_dict():
    d = dict(BASIC_INPUT_DICT)
    d[KEY_SPAN] = 20.0
    d[KEY_CARRIAGEWAY_WIDTH] = 7.5
    solve_extend_basic_input_dict(d)
    return d

def test_cross_section_hitboxes_and_editing(qapp):
    dual = BridgeDualCADWidget()
    dual.resize(800, 600)
    data = get_populated_input_dict()
    dual.update_from_osdag_inputs(data)
    widget = dual.cross_section_widget

    pixmap = QPixmap(800, 600)
    painter = QPainter(pixmap)
    widget.draw_cross_section(painter)
    painter.end()

    # Check registered hitboxes
    registered_keys = [hb["key"] for hb in widget.dimension_label_hitboxes]
    assert KEY_CARRIAGEWAY_WIDTH in registered_keys
    assert KEY_TS_GIRDER_SPACING in registered_keys
    assert KEY_TS_DECK_THICKNESS in registered_keys
    assert KEY_TS_DECK_OVERHANG in registered_keys
    assert KEY_TS_OVERALL_WIDTH in registered_keys

    # Check editable flags
    for hb in widget.dimension_label_hitboxes:
        if hb["key"] in (KEY_CARRIAGEWAY_WIDTH, KEY_TS_GIRDER_SPACING, KEY_TS_DECK_THICKNESS):
            assert hb["editable"] is True
        elif hb["key"] in (KEY_TS_DECK_OVERHANG, KEY_TS_OVERALL_WIDTH):
            assert hb["editable"] is False

    # Simulate double clicking an editable hitbox
    editable_hb = next(hb for hb in widget.dimension_label_hitboxes if hb["key"] == KEY_CARRIAGEWAY_WIDTH)
    center = editable_hb["rect"].center().toPoint()
    event = QMouseEvent(QEvent.MouseButtonDblClick, center, Qt.LeftButton, Qt.LeftButton, Qt.NoModifier)
    widget.mouseDoubleClickEvent(event)

    assert widget._active_editor is not None
    assert isinstance(widget._active_editor, QLineEdit)
    assert not widget._active_editor.isHidden()
    assert float(widget._active_editor.text()) == pytest.approx(editable_hb["value"])

    # Test signal emission
    received_signals = []
    widget.parameter_edited.connect(lambda k, v: received_signals.append((k, v)))

    widget._active_editor.setText("8.0")
    widget._active_editor.returnPressed.emit()
    assert len(received_signals) == 1
    assert received_signals[0] == (KEY_CARRIAGEWAY_WIDTH, 8.0)
    assert widget._active_editor is None

def test_cross_section_locked_hitbox_blocks_edit(qapp):
    dual = BridgeDualCADWidget()
    dual.resize(800, 600)
    dual.update_from_osdag_inputs(get_populated_input_dict())
    widget = dual.cross_section_widget

    pixmap = QPixmap(800, 600)
    painter = QPainter(pixmap)
    widget.draw_cross_section(painter)
    painter.end()

    locked_hb = next(hb for hb in widget.dimension_label_hitboxes if hb["key"] == KEY_TS_OVERALL_WIDTH)
    center = locked_hb["rect"].center().toPoint()
    event = QMouseEvent(QEvent.MouseButtonDblClick, center, Qt.LeftButton, Qt.LeftButton, Qt.NoModifier)
    widget.mouseDoubleClickEvent(event)

    # Editor must NOT be created for locked parameter
    assert widget._active_editor is None

def test_top_view_hitboxes_and_editing(qapp):
    dual = BridgeDualCADWidget()
    dual.resize(800, 600)
    data = get_populated_input_dict()
    dual.update_from_osdag_inputs(data)
    widget = dual.top_view_widget

    pixmap = QPixmap(800, 600)
    painter = QPainter(pixmap)
    widget.draw_top_view(painter)
    painter.end()

    registered_keys = [hb["key"] for hb in widget.dimension_label_hitboxes]
    assert KEY_SPAN in registered_keys
    assert KEY_TS_GIRDER_SPACING in registered_keys
    assert KEY_MP_CB_SPACING in registered_keys

    # Span is editable
    span_hb = next(hb for hb in widget.dimension_label_hitboxes if hb["key"] == KEY_SPAN)
    assert span_hb["editable"] is True

    # Bracing spacing is locked
    bracing_hb = next(hb for hb in widget.dimension_label_hitboxes if hb["key"] == KEY_MP_CB_SPACING)
    assert bracing_hb["editable"] is False

    received_signals = []
    widget.parameter_edited.connect(lambda k, v: received_signals.append((k, v)))

    center = span_hb["rect"].center().toPoint()
    event = QMouseEvent(QEvent.MouseButtonDblClick, center, Qt.LeftButton, Qt.LeftButton, Qt.NoModifier)
    widget.mouseDoubleClickEvent(event)

    assert widget._active_editor is not None
    widget._active_editor.setText("25.0")
    widget._active_editor.returnPressed.emit()
    assert len(received_signals) == 1
    assert received_signals[0] == (KEY_SPAN, 25.0)

def test_dual_view_signal_forwarding(qapp):
    dual_view = BridgeDualCADWidget()
    received_signals = []
    dual_view.cad_parameter_edited.connect(lambda k, v: received_signals.append((k, v)))

    # Emit from child cross section
    dual_view.cross_section_widget.parameter_edited.emit(KEY_CARRIAGEWAY_WIDTH, 7.5)
    assert len(received_signals) == 1
    assert received_signals[0] == (KEY_CARRIAGEWAY_WIDTH, 7.5)

    # Emit from child top view
    dual_view.top_view_widget.parameter_edited.emit(KEY_SPAN, 30.0)
    assert len(received_signals) == 2
    assert received_signals[1] == (KEY_SPAN, 30.0)
