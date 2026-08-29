# PSR32 v0.2.1 — RGA-safe test build

The physical log showed repeated `RetroRun [ERROR] c_RkRgaBlit failed` messages followed by `Segmentation fault` and `emulator_exit_status=139`. The input diagnostics continued to update, so the shoulder mapping was not the cause of this crash.

The failing RGA dump contained a source rectangle with width `0` and height `0`, while the destination was `640×480`. Rockchip's RGA guide requires valid source and destination rectangles; this profile therefore avoids the 0.5× request by default and uses native internal resolution `1.0×`.

The build retains the requested `ps2.limitframerate = 30` and `retrorun_fps_counter = true`. The previous 0.5× settings remain available in `psr32-performance-lowres-experimental.cfg`, but are selected only with `PS2_USE_LOWRES=1` and are not recommended on the affected RK3326 image.

The launcher continues to keep the R36S shoulder-button correction active by default. This is a compatibility test, not a guarantee of full PS2 game compatibility or performance.
