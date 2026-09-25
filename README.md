# ABAP Dynamic Assignment

# ✅ Status: Release (3.0.0)

> **Open Source Contribution:** This project is community-driven and **Open Source**! 🚀
> If you spot a bug or have an idea for an enhancement, open an **Issue** or submit a **Pull Request**.

[![CI](https://github.com/greltel/abap-dynamic-assignment/actions/workflows/ci.yml/badge.svg)](https://github.com/greltel/abap-dynamic-assignment/actions/workflows/ci.yml)
[![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)](https://abaplint.app/stats/greltel/abap-dynamic-assignment/object_classifications)
[![ABAP Version](https://img.shields.io/badge/ABAP-7.58%2B-blue)](https://abaplint.app/stats/greltel/abap-dynamic-assignment/statement_compatibility)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-dynamic-assignment)
[![License](https://img.shields.io/badge/License-MIT-green)](https://github.com/greltel/abap-dynamic-assignment/blob/main/LICENSE)

A lightweight, dynamic runtime parameter framework for ABAP Cloud.
It decouples configuration values from code logic, allowing developers, functional consultants or key users
to maintain variables, ranges and mappings through a Fiori Elements application or a programmatic API,
bypassing hardcoded values and the rigid standard TVARVC table.

# Table of contents
1. [License](#license)
2. [Contributors-Developers](#contributors-developers)
3. [Key Benefits](#key-benefits)
4. [Prerequisites](#prerequisites)
5. [Installation](#installation)
6. [Upgrading from 2.x](#upgrading-from-2x)
7. [Authorization](#authorization)
8. [Usage](#usage)
9. [Architecture](#architecture)
10. [The configuration table](#the-configuration-table)
11. [Messages](#messages)
12. [Running the tests](#running-the-tests)
13. [Known limitations](#known-limitations)
14. [Contributing](#contributing)

## License
This project is licensed under the [MIT License](https://github.com/greltel/abap-dynamic-assignment/blob/main/LICENSE).

## Contributors-Developers
The repository was created by [George Drakos](https://www.linkedin.com/in/george-drakos/).

## Key Benefits

* **No more TVARVC:** Forget the limitations, clutter and rigid structure of the standard SAP TVARVC table.
* **Zero Hardcoding:** Keep your business logic clean. No more `IF bukrs = '1000'` or hardcoded configuration IDs.
* **Hot-Swap Parameters:** Change program behaviour, inclusion/exclusion rules and value mappings in
  Production without a Transport Request.
* **RTTS:** Builds single values, range tables (ready for `SELECT ... IN`) and mapping tables at runtime.
  Every value is converted into the type of the caller's own variable.
* **Classification, not only lookup:** `map_value` runs the configured rules against one value and
  answers which bucket it falls into, comparing in the configured DDIC type rather than on strings.
* **Validated on write:** A value its data element could not hold unchanged is refused when it is
  stored, instead of surfacing months later in whichever program reads it first. The Fiori application
  and the programmatic API run the same check, through the same class.
* **Zero-touch installation:** Pull, activate, publish. No source code to edit, no constant to adjust.
* **ABAP Cloud:** Written for ABAP for Cloud Development, released APIs only.
* **Testable by design:** Every collaborator sits behind an interface and is injected through the
  constructor, so consumers mock the framework and the framework mocks the system. No test depends on
  the user, the clock, the PFCG roles or the data of the system it runs on.
* **Unit Tested:** 146 ABAP Unit tests across fourteen test classes, on the OSQL Test Double
  Framework and `cl_abap_testdouble`. The same tests run off-stack on every push and pull request,
  transpiled to JavaScript by the [abaplint transpiler](https://github.com/abaplint/transpiler)
  against an in-memory SQLite database — no ABAP system needed for CI.
* **Fiori Elements App** built with RAP: validations, defaults, draft handling, optimistic locking and
  authorization checks.
* **Clean:** abaplint with an extended Clean ABAP rule set runs on every push and pull request.
  Zero findings and a green test run are the merge bar.

## Prerequisites

* SAP S/4HANA 2023 FPS03 or higher (ABAP 7.58), or SAP BTP ABAP Environment
* Authorization object `ZDA_VAR` — see [Authorization](#authorization)

## Installation

1. Pull the repository with [abapGit](http://abapgit.org) into a package with the language version
   *ABAP for Cloud Development*.
2. Create the authorization field and object **before** activating — see [Authorization](#authorization).
   The behavior pool and the DCL reference `ZDA_VAR`.
3. Activate everything.
4. Publish the service binding `ZUI_DA_VARIANTS_O4`.
5. Create the IAM App, Business Catalog and Launchpad tile so that the application reaches your users.

That is all. The framework instantiates without arguments on its own table `ZTDA_VARIANTS`.

## Upgrading from 2.x

3.0.0 renames the RAP objects and the tables. There is no in-place upgrade; treat it as a fresh
installation next to the old one:

| 2.x | 3.0.0 |
|---|---|
| `ZDA_VARIANTS`, `ZDA_VARIANTS_D` | `ZTDA_VARIANTS`, `ZTDA_VARIANTS_D` |
| `ZI_DA_VARIANTS` (view, behavior definition, access control) | `ZR_DA_VARIANTS` |
| `ZBP_I_DA_VARIANTS` | `ZBP_R_DA_VARIANTS` |
| `ZCL_DA_VARIANTS=>check_value( )`, `=>data_element_exists( )` | `ZIF_DA_VALUE_CHECK` on `ZCL_DA_VALUE_CHECK` |
| `NEW zcl_da_variants( table_name = … )` | needs `packages = …` as well, unless the table is the shipped one |
| Text symbols | Message class `ZDA` |

Copy the rows of `ZDA_VARIANTS` into `ZTDA_VARIANTS` (same structure), then delete the 2.x objects.
Consumers that only hold `ZIF_DA_VARIANTS` and call `get_variant`, `set_variant`, `map_value` or
`delete_variant` compile unchanged.

## Authorization

The framework ships an authorization object that the RAP handlers check on every create, update and delete.

**Authorization field** (ADT → New → Other ABAP Repository Object → Authorization Field):

| Field | Data element |
|---|---|
| `ZDA_PROG` | `ZDE_DA_PROGNAME` |

**Authorization object** (ADT → New → Other ABAP Repository Object → Authorization Object):

| Object | Fields | Permitted activities |
|---|---|---|
| `ZDA_VAR` | `ACTVT`, `ZDA_PROG` | 01 Create, 02 Change, 03 Display, 06 Delete |

Build two PFCG roles — most users only need to see what is configured:

| Role | `ACTVT` | `ZDA_PROG` |
|---|---|---|
| Display | `03` | `*` or specific programs |
| Maintain | `01, 02, 03, 06` | `*` or specific programs |

> **`03` is mandatory in the maintain role as well.** The DCL grants read access through
> `aspect pfcg_auth ( ZDA_VAR, ZDA_PROG, ACTVT = '03' )`, and RAP reads the instance before every
> update or delete. Without `03` the user sees "record not found" while holding change authorization.

> **The DCL protects the Fiori application, not the programmatic API.** `get_variant` reads the table
> directly, so a background job is never filtered by the authorizations of a user. That is intentional —
> a scheduled job must not depend on who happens to be logged on. `set_variant` and `delete_variant`
> write for the same reason, without an authority check. Know that before you expose them.

## Usage

### Reading variants programmatically

1. Declare variables for your target data types. A single value, a range, or a table.
2. Instantiate `ZCL_DA_VARIANTS` behind `ZIF_DA_VARIANTS`.
3. Call `get_variant`. Only the targets you actually supply are computed.
4. Use the result directly in your business logic or in Open SQL.

```abap
DATA product       TYPE i_product-product.
DATA product_range TYPE RANGE OF i_product-product.
DATA products      TYPE STANDARD TABLE OF i_product-product WITH EMPTY KEY.

TRY.
    DATA(variants) = CAST zif_da_variants( NEW zcl_da_variants( ) ).

    variants->get_variant(
      EXPORTING parameter_id = 'VALID_MATERIALS'
                program_name = 'GLOBAL'
      IMPORTING field_value  = product           " the first single value
                range        = product_range     " a real RANGE OF, ready for a WHERE clause
                values       = products ).       " one row per active variant

    SELECT FROM i_product
      FIELDS product, productgroup
      WHERE product IN @product_range
      INTO TABLE @DATA(matching_products).

  CATCH zcx_da_variants INTO DATA(error).
    " error->get_text( ) carries the reason, error->if_t100_message~t100key the message key
ENDTRY.
```

> **Range types come from the configuration.** The DDIC type of the returned range is taken from the
> `DataElement` column. Leave it empty to get the native 255 character column type, which converts
> cleanly into any character-like range. Set it when your caller uses a numeric or date range.

### Creating variants programmatically

Use `set_variant` for initial data loads, seed data or API integrations.

```abap
TRY.
    DATA(variants) = CAST zif_da_variants( NEW zcl_da_variants( ) ).

    variants->set_variant(
      parameter_id = 'DEFAULT_PLANTS'
      program_name = 'ZTEST'
      counter      = '00001'                      " omit to append a new row
      field_value  = '1000'
      high_value   = '2000'
      sign         = zcl_da_variants=>sign_include
      option       = zcl_da_variants=>opt_bt
      description  = 'Default Plant for Operations' ).

  CATCH zcx_da_variants INTO DATA(error).
    " validation failed, or the database rejected the row
ENDTRY.
```

> **The caller owns the LUW.** `set_variant` does not commit. Pass `commit = abap_true` only from
> standalone scripts — never from a RAP handler, a determination or a validation.

> **Seed data is idempotent.** Passing an existing `counter` replaces that row instead of appending
> a new one, so a load script can run twice without duplicating configuration.

`set_variant` rejects anything the framework would not be able to read back: a missing `Parameterid`
or `Value`, an unknown or non-elementary data element, `BT` or `NB` without an upper bound, and an
upper bound on any other operator. The Fiori application enforces the same rules through the same
code, so both doors accept exactly the same rows.

> **The value has to fit its data element.** `1000` configured against a one character element would
> come back as `1`, and `ABC` against a `NUMC` element would come back as zeros. Both are refused on
> write. The check knows what each type loses in silence: `CHAR` truncates on the right, `NUMC` keeps
> only the digits, and a date field is character like, so `20240230` would be copied straight in as a
> day that does not exist. Leading zeros that `NUMC` adds by itself are not a loss and stay accepted.

> **Appending never overwrites.** Without a `counter` the row is inserted, never replaced. If another
> LUW takes the number in between, the next one is allocated and the insert is repeated. An exhausted
> counter range is reported as an error, not wrapped around to `00000`.

### Removing variants

```abap
TRY.
    DATA(variants) = CAST zif_da_variants( NEW zcl_da_variants( ) ).

    " one row
    DATA(removed) = variants->delete_variant( parameter_id = 'DEFAULT_PLANTS'
                                              program_name = 'ZTEST'
                                              counter      = '00002' ).

    " the whole parameter
    removed = variants->delete_variant( parameter_id = 'DEFAULT_PLANTS'
                                        program_name = 'ZTEST' ).

  CATCH zcx_da_variants INTO DATA(error).
    " no parameter was named, or the database refused the delete
ENDTRY.
```

`delete_variant` returns the number of rows it removed. Removing what is not there is not an error,
so a cleanup script can run twice. A blank `parameter_id` is refused, because without it the call
would clear whatever happens to carry a blank key.

> **The caller owns the LUW here as well.** Pass `commit = abap_true` only from standalone scripts.

### Value mapping

Beyond filtering, the framework can translate. A mapping variant answers *"what does X correspond to?"*
rather than *"is X in scope?"*.

| Progname | Parameterid | Counter | Sign | Opt | Value | MappingValue |
|---|---|---|---|---|---|---|
| ZORDER_IF | ORDER_TYPE_MAP | 1 | I | EQ | `CUST_STD` | `OR` |
| ZORDER_IF | ORDER_TYPE_MAP | 2 | I | EQ | `CUST_RET` | `RE` |

```abap
DATA pairs_ref TYPE REF TO data.
FIELD-SYMBOLS <pairs> TYPE STANDARD TABLE.

variants->get_variant( EXPORTING parameter_id   = 'ORDER_TYPE_MAP'
                                 program_name   = 'ZORDER_IF'
                       IMPORTING mapping_values = pairs_ref ).

ASSIGN pairs_ref->* TO <pairs>.

LOOP AT <pairs> ASSIGNING FIELD-SYMBOL(<pair>).
  ASSIGN COMPONENT 'VALUE'         OF STRUCTURE <pair> TO FIELD-SYMBOL(<from>).
  ASSIGN COMPONENT 'MAPPING_VALUE' OF STRUCTURE <pair> TO FIELD-SYMBOL(<to>).
  " <from> is the incoming code, <to> is the value to post with
ENDLOOP.
```

The table is returned as a data reference because the type of the `MAPPING_VALUE` column is only known
at runtime, from the configured `MappingDataElement`. If a parameter holds a single row, use
`mapping_field_value` instead and skip the table entirely.

> **Two ways to read the same rows.** A mapping table built with `mapping_values` pairs `Value` with
> `MappingValue` and ignores the range fields. `map_value` uses them as the rule that decides which
> pair applies. Rows written for the first style work in the second: an `EQ` row simply matches its
> own value.

### Classifying a value

`get_variant` answers *"which values are in scope"*. `map_value` reads the same rows the other way
round and answers *"which bucket does this one value fall into"*. Every active row is a rule,
evaluated in counter order, with the operator and the bounds it carries.

| Progname | Parameterid | Counter | Sign | Opt | Value | HighValue | MappingValue |
|---|---|---|---|---|---|---|---|
| ZPLANTS | PLANT_REGION | 1 | E | EQ | `1500` | | |
| ZPLANTS | PLANT_REGION | 2 | I | BT | `1000` | `1999` | `NORTH` |
| ZPLANTS | PLANT_REGION | 3 | I | BT | `2000` | `2999` | `SOUTH` |

```abap
DATA region TYPE c LENGTH 10.

variants->map_value( EXPORTING parameter_id  = 'PLANT_REGION'
                               program_name  = 'ZPLANTS'
                               input         = '1200'
                     IMPORTING mapping_value = region       " NORTH
                               matched       = DATA(matched) ).
```

The first rule that answers decides. Row 1 carries `sign_exclude`, so plant `1500` stops the search
and comes back unmatched even though row 2 would otherwise have covered it. That is how a hole is
punched into a range that maps as a whole.

> **The comparison runs in the configured DDIC type.** A `BT 9 AND 100` on a numeric element matches
> `50`. On the stored 255 character strings the same rule would reject it, because `'50'` sorts below
> `'9'`. Set `DataElement` whenever the values are numeric or dates. Patterns (`CP`, `NP`) always
> compare character wise, wildcards included.

> **A value that no rule covers is not an error.** `matched` comes back `abap_false` and
> `mapping_value` stays initial. Only an unknown parameter raises.

### Injecting your own configuration table

```abap
DATA(variants) = CAST zif_da_variants(
                     NEW zcl_da_variants( table_name = 'ZMY_OWN_VARIANTS'
                                          packages   = 'ZMY_PACKAGE' ) ).
```

The injected table must be **structurally identical** to `ZTDA_VARIANTS`. You name the packages it
may live in; the constructor validates the name with `cl_abap_dyn_prg=>check_table_name_str` and
raises `ZCX_DA_VARIANTS` when the table is unknown, lives elsewhere, or when no package list is given.
The shipped table needs no list.

### Testing a consumer

Consumers hold `ZIF_DA_VARIANTS`, so a consumer's unit test never needs the configuration table:

```abap
DATA(variants) = CAST zif_da_variants( cl_abap_testdouble=>create( 'ZIF_DA_VARIANTS' ) ).

cl_abap_testdouble=>configure_call( variants )->set_parameter( name  = 'field_value'
                                                               value = '1000' ).
variants->get_variant( EXPORTING parameter_id = 'DEFAULT_PLANT' IMPORTING field_value = DATA(plant) ).

DATA(cut) = NEW zcl_my_consumer( variants ).
```

## Architecture

```
ZIF_DA_VARIANTS ──── ZCL_DA_VARIANTS (facade)
                        │
                        ├── ZIF_DA_REPOSITORY ──── ZCL_DA_REPOSITORY      every database access
                        ├── ZIF_DA_VALUE_CHECK ─── ZCL_DA_VALUE_CHECK     RTTS type checks
                        ├── ZIF_DA_RULE_MATCHER ── ZCL_DA_RULE_MATCHER    sign / option / bounds
                        └── ZIF_DA_SYSTEM_CONTEXT  ZCL_DA_SYSTEM_CONTEXT  user and clock

ZR_DA_VARIANTS (RAP root) ── ZBP_R_DA_VARIANTS
                                │  lcl_variants_factory (composition root, inject_* hooks)
                                ├── ZIF_DA_AUTHORIZATION ── ZCL_DA_AUTHORIZATION   AUTHORITY-CHECK ZDA_VAR
                                ├── ZIF_DA_REPOSITORY                             early numbering
                                └── ZIF_DA_VALUE_CHECK                            validations

ZC_DA_VARIANTS (projection) ── ZUI_DA_VARIANTS ── ZUI_DA_VARIANTS_O4 (OData V4, UI)
ZCX_DA_VARIANTS ── if_t100_dyn_msg + if_abap_behv_message, message class ZDA
```

Every collaborator of `ZCL_DA_VARIANTS` is an optional constructor parameter with a production
default. The behavior pool resolves its collaborators through a local factory, which is what lets the
RAP tests inject an authorization double instead of depending on the PFCG roles of whoever runs them.

`ZCX_DA_VARIANTS` implements `IF_ABAP_BEHV_MESSAGE`, so one exception object carries a message from
the value check straight into `reported-%msg` of the Fiori application, with the same number and the
same variables the API caller would see.

## The configuration table

| Column | Meaning |
|---|---|
| `PROGNAME` | Program scope. Use `GLOBAL` for parameters shared across programs |
| `PARAMETERID` | The parameter being configured |
| `COUNTER` | Sequence inside one program and parameter, assigned automatically |
| `IS_ACTIVE` | Only active rows are returned. Defaults to set on creation |
| `SIGN` / `OPT` | Range semantics, `I`/`E` and `EQ`, `BT`, `CP`, … |
| `VALUE` / `HIGH_VALUE` | The value, and the upper bound for `BT` and `NB` |
| `DATA_ELEMENT` | DDIC type of the value. Empty means the native column type |
| `MAPPING_VALUE` | The value this row translates to |
| `MAPPING_DATA_EL` | DDIC type of the mapping value |
| `DESCRIPTION` | Free text. `set_variant` generates one when it is left empty |

`ZTDA_VARIANTS` has delivery class `C` and restricted data maintenance. Administrative fields are
filled by the RAP framework and by `set_variant`.

## Messages

All messages come from the message class `ZDA` and are translatable as one unit. The constants of
`ZCX_DA_VARIANTS` name them, so a caller can react to a specific cause:

```abap
CATCH zcx_da_variants INTO DATA(error).
  IF error->if_t100_message~t100key = zcx_da_variants=>no_active_variant.
    " nothing configured yet, fall back to the default
  ENDIF.
```

| Number | Constant | Raised when |
|---|---|---|
| 003 | `no_active_variant` | No active row exists for the parameter |
| 005 / 006 | `invalid_data_element` / `invalid_mapping_element` | A configured type does not exist or is not elementary |
| 011 / 024 | `table_not_allowed` / `packages_missing` | The injected table is refused |
| 012 / 014 | `inconsistent_elements` / `inconsistent_mapping_elements` | Rows of one parameter disagree on their type |
| 013 / 019 | `high_value_missing` / `high_value_not_allowed` | The upper bound does not match the operator |
| 015 / 016 | `counter_exhausted` / `counter_not_secured` | No free counter |
| 017 / 018 | `parameter_missing` / `value_missing` | A mandatory field is blank |
| 020 – 023 | `value_not_convertible`, `value_does_not_fit`, `invalid_date`, `invalid_time` | The value would not survive its type |
| 001 / 002 / 004 / 009 / 010 | conversion, RTTS, database and write errors | The cause is chained in `previous` |

## Running the tests

```
ADT: right click the package -> Run As -> ABAP Unit Test   (Ctrl+Shift+F10)
```

146 tests across fourteen test classes. None of them touches real data, the real user, the real
clock or the real authorizations:

| Test class | Covers |
|---|---|
| `ltc_variants` | Ranges, value tables, mapping tables, normalisation, validation, stamping, the constructor |
| `ltc_defects` | Regressions for the defects closed in 2.1.0 |
| `ltc_value_types` | The type check that runs before a value is written |
| `ltc_mapping` | `map_value`, every operator, exclusion and rule order |
| `ltc_delete` | `delete_variant`, single rows and whole parameters |
| `ltc_exception` | T100 text, severity, chaining and variable length of `ZCX_DA_VARIANTS` |
| `ltc_repository` | Active rows, draft counters, bulk counter reads, taken keys, delete counts |
| `ltc_rule_matcher` | Typed comparison, patterns, `NB`, unknown operators, overflowing input |
| `ltc_numbering` | Early numbering, pending drafts and the exhausted key range |
| `ltc_defaults` | The determination that fills `IsActive`, `Sign` and `Opt` |
| `ltc_validations` | All three save-time validations, triggered through a real save |
| `ltc_authorizations` | Global and instance authorization through an injected double |
| `ltc_option_vh` | The options query provider, including the paging contract |
| `ltc_sign_vh` | The sign query provider, including the paging contract |

Static checks and the transpiled unit tests, locally or in CI (Node 22, see `.nvmrc`):

```bash
npm ci          # pinned @abaplint toolchain from package-lock.json
npm run lint    # abaplint, zero findings expected
npm test        # transpile src/ to JavaScript and run the ABAP Unit tests off-stack
npm run check   # both
```

The same two jobs run on every push and pull request through `.github/workflows/ci.yml`.
A handful of tests need the real system (package check, `CONV #` into a generic parameter) and
run only in ADT; they are listed with a reason under `options.skip` in `abap_transpile.json`.

## Known limitations

* **The API does not check authorizations.** `ZDA_VAR` protects the Fiori application through the
  behaviour definition and the DCL. `set_variant` and `delete_variant` write directly, so anything
  that can call the class can change configuration.
* **Direct table access bypasses every validation.** Data maintenance on `ZTDA_VARIANTS` is
  restricted, but a report writing the table directly still gets past every check.
* **Message variables hold 50 characters.** A cause text longer than that is cut in the message; the
  full text stays available in `error->previous`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Every pull request must pass the CI workflow (abaplint and
the transpiled unit tests) and ship its ABAP Unit tests.
