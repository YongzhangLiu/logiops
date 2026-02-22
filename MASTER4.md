# MX Master 4 Button Reference

## Remappable Buttons

1. **0x52** - Middle mouse button (scroll wheel click)
2. **0x53** - Back button
3. **0x56** - Forward button
4. **0xc3** - Thumb button (side button, in line with back/forward)
5. **0xc4** - Top scroll mode switch button (ratchet/free-spin toggle)
6. **0x1a0** - Haptic button (new to Master 4)

## Non-Remappable Buttons

- **0x50** - Primary mouse button (left click)
- **0x51** - Secondary mouse button (right click)

## Thumb Wheel

- **CID:** 0x2150
- **Capabilities:** timestamp, touch
- **Resolution:** native (20), diverted (120)
- **Note:** Single tap is NOT supported

---

## Raw Debug Output

```
[INFO] Device found: MX Master 4 on /dev/hidraw5:2
[DEBUG] /dev/hidraw5:2 remappable buttons:
[DEBUG] CID  | reprog? | fn key? | mouse key? | gesture support?
[DEBUG] 0x50 |         |         | YES        | 
[DEBUG] 0x51 |         |         | YES        | 
[DEBUG] 0x52 | YES     |         | YES        | YES
[DEBUG] 0x53 | YES     |         | YES        | YES
[DEBUG] 0x56 | YES     |         | YES        | YES
[DEBUG] 0xc3 | YES     |         | YES        | YES
[DEBUG] 0xc4 | YES     |         | YES        | YES
[DEBUG] 0xd7 | YES     |         |            | YES
[DEBUG] 0x1a0 | YES     |         | YES        | YES
[DEBUG] Thumb wheel detected (0x2150), capabilities:
[DEBUG] timestamp | touch | proximity | single tap
[DEBUG] YES       | YES   | NO        | NO        
[DEBUG] Thumb wheel resolution: native (20), diverted (120)
```


pactl set-sink-volume @DEFAULT_SINK@ 100%

sudo cp ../logid.cfg /etc/ && sudo systemctl restart logid

make -j$(nproc) && sudo make install