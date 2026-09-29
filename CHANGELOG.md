# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-29

### Added

- Initial stable release of `form_dirty_state`.
- `DirtyFormController` for tracking form dirty state.
- Field-level dirty state inspection with `isFieldDirty()`.
- Modified field inspection with `dirtyFields`.
- Changed-value extraction with `changes`.
- Baseline and current value inspection.
- Deep equality for supported nested collections and values.
- Defensive snapshotting to protect internal state.
- `reset()` support for restoring baseline values.
- `markSaved()` support for establishing a new baseline.
- Synchronous change notifications through `onChanged` and listeners.
