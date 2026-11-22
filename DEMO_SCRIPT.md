# 🎬 2-Minute Screencast Demonstration Script
**Project**: OsdagBridge UI, 2D CAD, and Plotting Enhancements (FOSSEE Screening Task)  
**Candidate**: Nizam (`nizamulhaq500`)  
**Target Branch**: `dev`  
**Collaborator Invited**: `Nidhikhare12`  

---

## 🛠️ Step 0: Quick 30-Second Setup Before Hitting Record

1. **Open a Terminal Window**:
   - Keep a terminal window open in the background sized nicely at the bottom or corner of your screen.
   - Enter the directory:
     ```bash
     cd /Users/nizam/internship/OsdagBridge
     ```
   - Type this command but **don't press Enter yet**:
     ```bash
     QT_PLUGIN_PATH=/opt/anaconda3/envs/osdagbridge-env/lib/python3.12/site-packages/PySide6/Qt/plugins pytest tests/unit/
     ```

2. **Launch OsdagBridge**:
   - In another terminal tab or window, run:
     ```bash
     conda activate osdagbridge-env
     python -m osdagbridge.desktop
     ```
   - Maximize or size OsdagBridge to fill your screen.
   - Load or open the Plate Girder bridge template so the 2D CAD view and 3D viewer are ready.

3. **Start macOS Screen Recorder**:
   - Press **`Cmd + Shift + 5`** on your Mac keyboard.
   - In the toolbar at the bottom:
     - Select **Record Entire Screen** (or Record Selected Portion around the app).
     - Click **Options** $\to$ under **Microphone**, make sure **MacBook Microphone** (or your headset) is selected so your voice is recorded.
   - Click **Record**! Take a deep breath, and read the script below.

---

## 🎙️ The Word-for-Word Teleprompter Script

### ⏱️ [0:00 - 0:18] Introduction
> **🖱️ On Screen**: Keep OsdagBridge visible with the Plate Girder template open.
> 
> **🗣️ Say Aloud**:  
> *"Hello! My name is Nizam, GitHub username `nizamulhaq500`. This is my video demonstration for the FOSSEE Internship screening task on OsdagBridge: UI, 2D CAD, and Plotting Enhancements. All three tasks have been implemented and verified with seventeen automated unit tests."*

---

### ⏱️ [0:18 - 0:48] Task I: Interactive 2D CAD Parameter Editing
> **🖱️ On Screen**: 
> 1. Move your mouse over the dimension labels in the Cross-Section view (notice the cursor turns into a pointing hand).
> 2. Double-click on **Carriageway Width** (`7.5 m`). The inline text box appears.
> 3. Type `8.4` and press **Enter**. Show that the girders re-space automatically and the Input Dock updates!
> 4. Double-click on **Overall Width** (`9.6 m`). Notice the non-blocking tooltip appears saying it is derived and locked.
> 5. Switch to the **Top View** tab, and double-click on **Span Length** to show it is also editable.
> 
> **🗣️ Say Aloud**:  
> *"Starting with Task One: Interactive 2D CAD Editing. As I hover over the dimension callouts on the cross-section, the cursor changes to a pointing hand. Double-clicking an editable dimension, like Carriageway Width, brings up an inline floating editor. If I change it from 7.5 to 8.4 meters and press Enter, the bridge configuration solver immediately recalculates the girder spacing, updates the Input Dock, and re-renders the CAD canvas.*  
> *Derived dimensions, like Overall Width and Cantilever Overhang, are mathematically locked to prevent over-constraining the model. If I double-click Overall Width, a tooltip pops up explaining that it is mathematically derived and read-only. The same editing capability is active in the Top View for the span length."*

---

### ⏱️ [0:48 - 1:18] Task II: Additional Inputs Pre-Save Validation & Unsaved Warning
> **🖱️ On Screen**: 
> 1. Click to open the **Additional Inputs** dialog.
> 2. Go to the **Deck Slab** tab. Under Crash Barrier, change the dropdown from standard to **"Custom"**.
> 3. Delete the number in the **Crash Barrier Width** box (leave it blank).
> 4. Click the **Save Inputs** button $\to$ The Critical Error dialog pops up!
> 5. Click OK on the error. Put a valid number back (e.g. `0.45`).
> 6. Change another small value, and then click the window's **close [X]** button or **Cancel** button $\to$ The Discard Warning dialog pops up!
> 7. Click **Discard** to close it.
> 
> **🗣️ Say Aloud**:  
> *"Next is Task Two: Additional Inputs Validation and Modification Tracking. I will open the Additional Inputs dialog and switch to the Deck Slab tab. If I select a Custom Crash Barrier and leave the custom width empty, clicking 'Save Inputs' immediately halts the save and displays a critical error dialog stating: 'The custom value for Crash Barrier Width cannot be empty.'*  
> *Once I provide a valid value, if I modify any field and attempt to close the window without saving, the application detects the modified state and displays a confirmation prompt asking if I want to discard unsaved changes, preventing accidental data loss."*

---

### ⏱️ [1:18 - 1:48] Task III: Transverse Member Results Plotting
> **🖱️ On Screen**: 
> 1. In the Output Dock, switch to the **Analysis** tab.
> 2. Click the Member dropdown and select **"Transverse Members"**.
> 3. Click through the 3D views:
>    - Show the **Shear Force Diagram (SFD)** (stepped blue polygons with vertical drop lines).
>    - Show the **Bending Moment Diagram (BMD)** (continuous coral/crimson sagging moment curves).
>    - Show the **Deflection Diagram** (purple curves showing max sag across diaphragms and cross bracings).
> 
> **🗣️ Say Aloud**:  
> *"Now for Task Three: Transverse Member Results Plotting. In the Output Dock, I open the Member dropdown and select the newly added option: 'Transverse Members'.*  
> *The 3D diagram engine topologically reconstructs the continuous lines for End Diaphragm 1, intermediate Cross Bracings, and End Diaphragm 2. In the Shear Force Diagram, we see stepped force polygons with vertical drop lines at girder intersections. The Bending Moment Diagram renders continuous transverse distributions conforming to civil engineering sign conventions, and the Deflection diagram displays vertical displacement profiles with peak sag labeled across the full width of the deck."*

---

### ⏱️ [1:48 - 2:05] Automated Tests & Conclusion
> **🖱️ On Screen**: 
> 1. Bring up your terminal window with `pytest tests/unit/`.
> 2. Press **Enter** and let the 17 tests run and pass green (`17 passed in 7.35s`).
> 
> **🗣️ Say Aloud**:  
> *"Finally, here is the automated test suite. Running pytest on all unit tests confirms that all seventeen tests pass cleanly across Task One, Task Two, and Task Three.*  
> *All source code, the comprehensive PDF report, and unit tests are pushed to the dev branch of my GitHub fork, and Nidhikhare12 has been invited as a collaborator. Thank you!"*

---

## 🛑 After Recording:

1. Press **`Cmd + Control + Esc`** (or the small square Stop icon in the top Mac menu bar) to stop recording.
2. The video will be saved to your **Desktop** or **Movies** folder as a `.mov` file.
3. Open YouTube $\to$ click **Create (+)** $\to$ **Upload video**.
4. Set visibility to **Unlisted** (anyone with the link can view).
5. Copy your YouTube link and you're ready to submit!
