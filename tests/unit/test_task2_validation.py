import pytest
from PySide6.QtWidgets import QApplication, QLineEdit, QComboBox

from osdagbridge.desktop.ui.dialogs.additional_input.additional_inputs import AdditionalInputs
from osdagbridge.core.bridge_types.plate_girder.defaults import BASIC_INPUT_DICT, solve_extend_basic_input_dict
from osdagbridge.core.utils.common import (
    KEY_SPAN, KEY_CARRIAGEWAY_WIDTH, KEY_CB_TYPE, KEY_CB_WIDTH, KEY_CB_HEIGHT, KEY_CB_LOAD
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
    d[KEY_CARRIAGEWAY_WIDTH] = 5.0
    solve_extend_basic_input_dict(d)
    return d

def test_initial_state_not_modified(qapp):
    dialog = AdditionalInputs()
    dialog.set_input_dictionary(get_populated_input_dict())
    assert dialog.is_modified is False

def test_modification_flag_set_on_edit(qapp):
    dialog = AdditionalInputs()
    dialog.set_input_dictionary(get_populated_input_dict())
    assert dialog.is_modified is False

    dialog._mark_modified()
    assert dialog.is_modified is True

def test_validate_custom_fields_empty(qapp):
    dialog = AdditionalInputs()
    dialog.set_input_dictionary(get_populated_input_dict())

    # Set Crash Barrier combo to Custom
    cb_combo = dialog.findChild(QComboBox, KEY_CB_TYPE)
    assert cb_combo is not None
    cb_combo.setCurrentText("Custom")

    # Clear Crash Barrier width
    cb_width_edit = dialog.findChild(QLineEdit, KEY_CB_WIDTH)
    assert cb_width_edit is not None
    cb_width_edit.setText("")

    err = dialog._validate_custom_fields()
    assert err is not None
    assert "Error: The custom value for" in err
    assert "cannot be empty." in err

def test_validate_custom_fields_valid(qapp):
    dialog = AdditionalInputs()
    dialog.set_input_dictionary(get_populated_input_dict())

    # By default, inputs are standard, validate_custom_fields should return None
    err = dialog._validate_custom_fields()
    assert err is None
