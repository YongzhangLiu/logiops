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

### The Initial Config Requirement: Why `target: true` MUST be in `logid.cfg`
A major quirk discovered is that the `target` setting must be set to `true` in the initial `logid.cfg` file, even though our default starting state (Ratchet mode) intends for it to be `false` (which is forced dynamically in code later). 

**The Reason:**
During LogiOps daemon startup (`HiresScroll::_configure()`), if the config has `target: false`, the daemon optimizes its initialization by **completely skipping** the setup for event diversion hooks and axis gesture parsing. 
*   If you boot with `target: false`, the interception framework is never built. When our C++ code later tries to execute `_hires_scroll->setTargetMode(true)` at runtime to re-enable smooth scrolling, the hook fails silently because the underlying routing was never configured in memory.
*   By setting `target: true` in the config file, we force LogiOps to build the interception framework for `REL_WHEEL_HI_RES` and the multipliers at initialization. Our custom C++ action can then safely toggle that interception pipeline on and off at will.

### Alignment with Official Documentation
The official description for the `target` field states:
> *This is an optional boolean field that defines whether mousewheel events should send as an HID++ notification or work normally (true for HID++ notification, false for normal usage). This option must be set to true to remap the scroll wheel action.*

This perfectly matches our empirical findings:
1. **"false for normal usage"**: When we toggle `setTargetMode(false)` in code for Ratchet mode, the mouse sends standard, native wheel events instead of high-density sparse HID++ packets. This is exactly why the scroll speed returned to normal in ratchet mode without doubling the multiplier!
2. **"must be set to true to remap the scroll wheel action"**: This explains our initialization quirk! Because we wanted to remap the high-resolution scrolling (applying an `axis_multiplier` of `0.8`), the config parser *must* read `target: true` at startup to actually instantiate that remapping sequence. If we initialized it as `false`, LogiOps respected the documentation—it never mapped the scroll wheel actions, which is why toggling it dynamically later failed silently.  

## 4. Working Configuration Snippet Reference
For the above C++ custom implementation to function properly, the config MUST look like this:

```properties
    hiresscroll:
    {
        hires: false;          // Start in Ratchet mode natively
        invert: false;
        target: true;          // MUST BE TRUE to build internal hooks, despite starting in Ratchet
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
