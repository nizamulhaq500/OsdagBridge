# 🎙️ OsdagBridge 2-Minute Video Voiceover Script

**Video Duration**: Exactly 2 minutes (02:01)  
**Video File**: `/Users/nizam/internship/demo_screen_recording.mp4`  
**Candidate**: Nizam (`nizamulhaq500`)  
**Total Word Count**: ~205 words (comfortable speaking pace: ~105 words/min)

---

## ⏱️ Scene-by-Scene Teleprompter Script

### ⏱️ [0:00 - 0:10] Introduction
> **Visual on screen**: OsdagBridge interface opens clean and maximized, displaying the 2D CAD cross-section and top view.
>
> 🗣️ **Say Aloud**:  
> *"Hello, I am Nizam. This is my demonstration for the OsdagBridge screening task, covering 2D CAD editing, input validation, and transverse member plotting."*

---

### ⏱️ [0:10 - 0:26] Task I: Interactive 2D CAD Parameter Editing
> **Visual on screen**: Inline text box appears over Carriageway Width (7.50 m), updates to 8.4, and immediately recalculates girder spacing (2.33 m) and input dock.
>
> 🗣️ **Say Aloud**:  
> *"Starting with Task One, double-clicking any editable dimension, like Carriageway Width, opens an inline editor. Changing this to 8.4 meters immediately triggers the layout solver, automatically updating girder spacing, overhang, and the input dock."*

---

### ⏱️ [0:26 - 0:38] Locked Derived Dimension & Tooltip
> **Visual on screen**: Double-clicks Overall Width (9.30 m). A non-blocking tooltip appears explaining it is mathematically derived.
>
> 🗣️ **Say Aloud**:  
> *"Derived dimensions like Overall Width are mathematically locked to prevent over-constraint. Double-clicking it displays a clear tooltip explaining that it is read-only."*

---

### ⏱️ [0:38 - 0:46] Top View CAD Editing
> **Visual on screen**: Switches to Top View CAD tab, activates inline editor on Span Length (20.0 m).
>
> 🗣️ **Say Aloud**:  
> *"The same interactive inline editing is also active in the Top View for bridge span length."*

---

### ⏱️ [0:46 - 1:12] Task II: Additional Inputs & Custom Barrier Validation
> **Visual on screen**: Additional Inputs dialog opens -> Deck Slab tab -> sets Crash Barrier to Custom -> leaves width blank -> clicks Save -> Critical Error dialog pops up.
>
> 🗣️ **Say Aloud**:  
> *"Moving to Task Two: Additional Inputs validation. When selecting a Custom Crash Barrier, if the width field is left empty, clicking Save immediately halts execution and alerts the user with a critical validation error dialog."*

---

### ⏱️ [1:12 - 1:26] Unsaved Changes Warning
> **Visual on screen**: Enters valid width (0.45 m), closes dialog without saving -> Unsaved changes confirmation dialog pops up -> Confirms discard.
>
> 🗣️ **Say Aloud**:  
> *"After restoring a valid value, attempting to close the window without saving triggers an unsaved changes confirmation dialog, effectively preventing accidental data loss."*

---

### ⏱️ [1:26 - 1:36] Task III: Transverse Member Selection
> **Visual on screen**: In the Output Dock, clicks Member dropdown and selects "Transverse Members".
>
> 🗣️ **Say Aloud**:  
> *"Finally, for Task Three, the Output Dock now includes Transverse Members in the member selection dropdown."*

---

### ⏱️ [1:36 - 1:56] 3D Transverse Diagrams (SFD & BMD)
> **Visual on screen**: 3D diagram view renders Shear Force Diagram with stepped polygons and vertical drop lines across diaphragms and cross bracings.
>
> 🗣️ **Say Aloud**:  
> *"Switching to the 3D plot renders continuous force distributions across end diaphragms and intermediate cross bracings, featuring stepped shear polygons and standard civil engineering sign conventions."*

---

### ⏱️ [1:56 - 2:01] Conclusion
> **Visual on screen**: Clean view of the final 3D model, application cleanly concludes.
>
> 🗣️ **Say Aloud**:  
> *"All implementations are verified with automated unit tests. Thank you!"*

---

## 🎧 How to Merge Your Voice with the Video

1. **Record your voice** (e.g. using iPhone Voice Memos or QuickTime Audio Recording) while looking at the timestamps above or playing `demo_screen_recording.mp4` on mute.
2. Save or AirDrop the audio file to your Mac (e.g. `voice.m4a`).
3. Run the automated merge script:
   ```bash
   cd /Users/nizam/internship/OsdagBridge
   ./tools/merge_audio.sh path/to/your/voice.m4a
   ```
4. This instantly creates:
   `/Users/nizam/internship/OsdagBridge_Final_Demo_Nizam.mp4`
   Ready for YouTube upload!
