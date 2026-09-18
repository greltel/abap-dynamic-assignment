# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- GitHub Actions workflow running abaplint on every push and pull request.
- `CONTRIBUTING.md`, issue and pull request templates, `.editorconfig`,
  `.gitattributes`.

## [3.0.0] — planned

Breaking release. See the migration notes in the README before upgrading.

### Changed
- **Objects renamed** to the project naming convention: `ZDA_VARIANTS` →
  `ZTDA_VARIANTS`, `ZDA_VARIANTS_D` → `ZTDA_VARIANTS_D`, `ZI_DA_VARIANTS` →
  `ZR_DA_VARIANTS` (view entity, behavior definition, access control),
  `ZBP_I_DA_VARIANTS` → `ZBP_R_DA_VARIANTS`. Existing configuration rows must
  be copied to the new table.
- Delivery class of the configuration table is now `C` (customizing).
- Messages moved from text symbols to the message class `ZDA`; every message
  now has a stable number and can be translated.
- `zcl_da_variants` split into a repository, a value checker, a rule matcher
  and a counter allocator; the public API behind `ZIF_DA_VARIANTS` is unchanged.
- Installation no longer requires editing `default_packages`.

### Fixed
- RAP unit tests no longer depend on the PFCG authorizations, the user or the
  clock of the system they run on.
- Obsolete `IS REQUESTED` replaced by `IS SUPPLIED`.
- An unknown data element was reported twice in the Fiori application.
- `LANGDEP` flag removed from the draft table.

## [2.1.0] — 2026-08-10

### Added
- `map_value`: classifies one value against the configured rules, comparing
  in the configured DDIC type, with exclude semantics and first-rule-wins
  ordering.
- `delete_variant`: idempotent removal of one row or a whole parameter,
  returning the number of rows removed.
- `check_value` as a public class method, shared by the API and the RAP
  validation `checkValueTypes`, rejecting values their data element could not
  hold unchanged (`CHAR` truncation, `NUMC` filtering, impossible dates and
  times).
- Unit tests for both RAP value help query providers, including a regression
  test for the paging contract.
- README sections for `map_value`, `delete_variant`, What's New and Known
  Limitations.

### Fixed
- Six defects found while extending the test suite, covered by `ltc_defects`.
- Message truncation in the Fiori application: RAP message texts longer than
  the message variable were cut silently.
- Early numbering could wrap the counter to `00000` when the key range was
  exhausted; it is now reported as an error.
- Values with trailing blanks in `CHAR30` fields were compared incorrectly.

## [2.0.0] — 2026-08-05

### Added
- `ZIF_DA_VARIANTS` interface in front of `ZCL_DA_VARIANTS`, with enumerated
  types for sign and option.
- `set_variant`: programmatic creation and replacement of variants with the
  same validations the Fiori application applies.
- Authorization object `ZDA_VAR` (fields `ACTVT`, `ZDA_PROG`), authorization
  class `ZDA`, DCL role on the root view entity, global and instance
  authorization handlers in the behavior pool.
- RAP validations `checkDataElements` and `checkRangeConsistency`,
  determination `setDefaults`, early numbering of the counter.
- Own domains and data elements (`ZDO_DA_*`, `ZDE_DA_*`) for every column of
  the configuration table.
- Value help query providers `ZCL_DA_SIGN_VH` and `ZCL_DA_OPTION_VH` reading
  domain fixed values; `ZCX_DA_QUERY`.
- Unit tests for the behavior pool.

### Changed
- `ZCL_DA_VARIANTS` rewritten with modern syntax, class-based error handling
  and RTTS based type conversion.
- Lock master uses `LastChangedAt` as total etag.

### Removed
- `ZI_DA_DATAELEMENT_VH`.

## [1.0.0] — 2026-03-16

### Added
- Runtime parameter framework replacing hardcoded values and `TVARVC`:
  configuration table `ZDA_VARIANTS`, `ZCL_DA_VARIANTS` with `get_variant`
  building single values, ranges and mapping tables at runtime.
- RAP managed, draft-enabled Fiori Elements application (`ZI_DA_VARIANTS`,
  `ZC_DA_VARIANTS`, `ZUI_DA_VARIANTS`, `ZUI_DA_VARIANTS_O4`).
- ABAP Unit tests on the OSQL Test Double Framework.
- abaplint configuration for ABAP for Cloud Development.

[Unreleased]: https://github.com/greltel/abap-dynamic-assignment/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/greltel/abap-dynamic-assignment/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/greltel/abap-dynamic-assignment/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/greltel/abap-dynamic-assignment/releases/tag/v1.0.0
