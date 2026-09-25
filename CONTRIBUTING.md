# Contributing

Thank you for considering a contribution. This document describes how the
project is developed so that a pull request can be merged without a round of
style comments.

## Ground rules

- **ABAP for Cloud Development only.** Every object in `src/` carries the
  ABAP language version *ABAP for Cloud Development* and uses released APIs
  only. Code that needs Standard ABAP does not belong in this repository.
- **Clean ABAP.** New code follows the
  [SAP Clean ABAP style guide](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md):
  no Hungarian prefixes, inline declarations, modern strict Open SQL
  (`SELECT FROM … FIELDS …`), `INSERT … INTO TABLE` over `APPEND`,
  `xsdbool( )` for booleans, no magic literals.
- **ABAP Doc on every public declaration** — classes, interfaces, exception
  classes, public methods and their parameters.
- **A unit test for every behaviour.** Bug fixes ship with the failing test
  that proves the bug first. Tests are `HARMLESS` / `SHORT`, run against test
  doubles (`cl_osql_test_environment`, `cl_abap_testdouble`) and never depend
  on the data, the user or the clock of the system they run on.
- **Exceptions, not return codes.** Failures surface through `ZCX_DA_VARIANTS`
  (API) or through `failed` / `reported` (RAP handlers). Messages live in the
  message class `ZDA`.

## Workflow

1. Fork the repository and create a branch from `main`
   (`feature/<topic>` or `fix/<issue-number>`).
2. Pull the branch into your system with [abapGit](https://abapgit.org) into a
   package that carries the *ABAP for Cloud Development* language version.
3. Develop in ADT. Format every changed object with **ABAP Cleaner** (default
   Clean ABAP profile) before staging.
4. Run the tests: right-click the package → *Run As* → *ABAP Unit Test*.
   Everything must be green.
5. Run the off-stack gate locally — the same two jobs run on every pull
   request (Node 22, see `.nvmrc`):

   ```bash
   npm ci
   npm run check   # abaplint + transpiled ABAP Unit tests
   ```

   Zero abaplint findings and a green test run are the merge bar. Do not
   install `@abaplint/cli` globally; the pinned version in `package-lock.json`
   is the one CI uses.
6. Stage with abapGit, push, open the pull request. Describe *what* changed
   and *why*; link the issue if there is one.
7. Add an entry under **Unreleased** in `CHANGELOG.md`.

## What a pull request needs

- Green CI workflow: abaplint and the transpiled unit tests.
- Unit tests for the change, green in ADT (paste the ABAP Unit result in the
  PR description).
- ABAP Doc for anything public that was added or changed.
- README updated when the public API or the installation steps change.

## Naming

| Object | Pattern | Example |
|---|---|---|
| Global class | `ZCL_DA_<purpose>` | `ZCL_DA_VARIANTS` |
| Interface | `ZIF_DA_<purpose>` | `ZIF_DA_VARIANTS` |
| Exception class | `ZCX_DA_<purpose>` | `ZCX_DA_VARIANTS` |
| Database table | `ZTDA_<entity>` | `ZTDA_VARIANTS` |
| Draft table | `ZTDA_<entity>_D` | `ZTDA_VARIANTS_D` |
| RAP root view entity + BDEF | `ZR_DA_<Entity>` | `ZR_DA_VARIANTS` |
| Projection view + BDEF + MDE | `ZC_DA_<Entity>` | `ZC_DA_VARIANTS` |
| Reuse / value help view | `ZI_DA_<Entity>` | `ZI_DA_PROGNAME_VH` |
| Behavior pool | `ZBP_R_DA_<Entity>` | `ZBP_R_DA_VARIANTS` |
| Service definition | `ZUI_DA_<Entity>` | `ZUI_DA_VARIANTS` |
| Service binding (UI, OData V4) | `ZUI_DA_<Entity>_O4` | `ZUI_DA_VARIANTS_O4` |
| Message class | `ZDA` | `ZDA` |
| Data element / domain | `ZDE_DA_<name>` / `ZDO_DA_<name>` | `ZDE_DA_VALUE` |
| Local test class / double / helper | `LTC_` / `LTD_` / `LTH_` | `LTC_VARIANTS` |

Test methods are named by behaviour, 30 characters at most:
`given_<context>_when_<action>_then_<outcome>`, dropping the trivial part.

## Reporting a bug

Open an issue with the *Bug report* template. A configuration row that
reproduces the problem (program, parameter, sign, option, value, data element)
and the exact message text get it fixed fastest.
