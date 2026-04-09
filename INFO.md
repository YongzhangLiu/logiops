# MX Master 4 Custom Configuration & Troubleshooting Info

This document summarizes the specific customizations, learnings, and underlying quirks discovered while configuring the Logitech MX Master 4 with LogiOps, specifically focusing on the custom scrolling mode toggle.

## 1. The Goal: Single-Button Scroll Mode Toggle
The objective was to use a single button (`0xc3`) to toggle between two distinct scrolling experiences:
*   **Smooth Mode:** Free-spinning wheel, high-resolution scrolling (`REL_WHEEL_HI_RES`), with a custom axis multiplier.
*   **Ratchet Mode:** Tactile stepped wheel, standard scrolling speed, avoiding high-resolution event processing which makes ratchet scrolling unusably slow.

## 2. The Custom Implementation: `ToggleSmartHires`
LogiOps out-of-the-box does not support toggling multiple orthogonal device features (SmartShift, HiRes Scroll, and Event Targeting) from a single action. To achieve this, a custom C++ action called `ToggleSmartHires` was implemented into the LogiOps source.

### Files Modified/Created:
*   `src/logid/actions/ToggleSmartHires.h` & `.cpp`: The logic for the new action.
*   `src/logid/features/HiresScroll.h` & `.cpp`: Exposed `setTargetMode()` publicly so the action could dynamically change the targeting mode.
*   `src/logid/config/schema.h` & `src/logid/actions/Action.cpp`: Registered the action in the config parser.
*   `src/logid/CMakeLists.txt`: Added the new action to the build tree.

### How `ToggleSmartHires` Works:
When triggered, it checks the current state of **SmartShift** (which controls the physical mechanical lock of the wheel) and inverses everything:
*   **If currently Smooth (SmartShift OFF):** 
    *   Turns SmartShift ON (engages ratchet)
    *   Turns HiRes Scroll OFF
    *   **Turns Target Mode OFF (`setTargetMode(false)`)**
*   **If currently Ratchet (SmartShift ON):**
    *   Turns SmartShift OFF (disengages ratchet)
    *   Turns HiRes Scroll ON
    *   **Turns Target Mode ON (`setTargetMode(true)`)**

## 3. The `target` Field Particularities and "Weird" Quirks

The most complex hurdle involved the `target` configuration field within the `hiresscroll` block.

### What is `target`?
In LogiOps, `target: true` instructs the daemon to "capture" (divert) the wheel events from the device and process them through the user's custom `up` and `down` gesture bindings (e.g., mapping them to `REL_WHEEL_HI_RES` with an `axis_multiplier`). `target: false` lets the wheel behave natively as a standard HID mouse wheel.

### Why was it toggled dynamically in the C++ code?
If we only toggled SmartShift and the HiRes capability bit on the device without toggling `target`:
*   **In Ratchet Mode:** The wheel generates far fewer physical events than in free-spin mode. Because LogiOps was still intercepting these sparse events (`target: true`) and applying the logic meant for high-density smooth scrolling, the resulting scroll speed onscreen was excruciatingly slow.
*   **The Fix:** By dynamically setting `setTargetMode(false)` when entering Ratchet mode, LogiOps stops trying to process the sparse events through the axis multiplier, allowing the OS to handle the standard native wheel packets. When returning to Smooth mode, `setTargetMode(true)` reactivates the custom high-res event multipliers.

### The True Root Cause: State Desynchronization
Initially, we believed `target: true` had to be explicitly set in the initial `logid.cfg` file because `target: false` somehow prevented the interception framework from being built. 

**This was incorrect.** The actual issue stemmed from how the backend mode was being modified directly. The original implementation called `_hires_scroll->setMode(...)` directly. This successfully updated the mouse's physical state, but LogiOps' internal `HiresScroll::_mask` and `HiresScroll::_mode` variables remained unchanged.

Whenever a subsequent IPC sync occurred (such as `_configure()` being called), LogiOps would read its internal, unmodified state variables and push them back to the device, silently reverting the HiRes bit and breaking the smooth scroll configuration.

### The Corrected Implementation
The codebase now properly uses `setHiresMode(bool)` and `setTargetMode(bool)` exposed by `HiresScroll`. These functions route through the IPC-aligned setters (`IPC::setHires` and `IPC::setTarget`), ensuring the internal state variables remain perfectly synchronized with the device's physical mode.

Because of this fix, the gesture hooks built during `_makeGesture(...)` function correctly, and we can finally boot directly into Ratchet mode with `target: false` as originally intended.

## 4. Working Configuration Snippet Reference
For the above C++ custom implementation to function properly, the config should look like this:

```properties
    hiresscroll:
    {
        hires: false;          // Start in Ratchet mode natively
        invert: false;
        target: false;         // Start without interception for normal ratchet speeds
        up:
        {
            mode: "Axis";
            axis: "REL_WHEEL_HI_RES";
            axis_multiplier: 1.3;
        };
        down:
        {
            mode: "Axis";
            axis: "REL_WHEEL_HI_RES";
            axis_multiplier: -1.3;
        };
    };
    
    // ...
    buttons: (
        {
            cid: 0xc3;
            action = { type: "ToggleSmartHires"; }; // Triggers our custom C++ toggle
        }
    )
```
