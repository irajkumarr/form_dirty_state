# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-29

### Added
- Initial stable release of `form_dirty_state`.
- `DirtyForm`: Core controller for tracking form dirty states, inspecting modified keys, changes, and baseline values.
- Deep equality engine for nested lists, maps, sets, primitives, `double.nan`, and cross-timezone `DateTime`.
- Defensive snapshotting preventing internal and external reference leaks and mutations.
- `reset([key])` support for resetting the entire form or a specific field.
- `markSaved()` support for committing the current state as the new baseline after saving.
- Lightweight synchronous change notifications with `addListener()` and unbind closure.
