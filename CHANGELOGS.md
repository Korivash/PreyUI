# PreyUI Changelog

## 3.0.12 - 2026-04-02

- Fixed protected frame taint caused by hooking managed extra action and zone ability button positioning through `SetPoint` and Blizzard frame-manager state.
- Switched extra action and zone ability repositioning to safe `OnShow` reapplication with combat deferral.

## 3.0.11 - 2026-04-02

- Fixed Blizzard taint caused by mutating secure `layoutIndex` data while injecting the PreyUI Escape menu button.
- Fixed alert skin anchor dependency errors caused by reparenting alert icons to frames anchored to those same icons.
- Synced documented release metadata with the addon version used by the `.toc`, runtime fallback, and README.

## 3.0.10

- Established the 3.0.10 addon release baseline in the `.toc` and runtime version metadata.
