# ABAP Dynamic Assignment
# ✅ Status: Release (2.0.0)
> **Open Source Contribution:** This project is community-driven and **Open Source**! 🚀
> If you spot a bug or have an idea for a cool enhancement, your contributions are more than welcome. Feel free to open an **Issue** or submit a **Pull Request**.

[![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)](https://abaplint.app/stats/greltel/abap-dynamic-assignment/object_classifications)
[![ABAP Version](https://img.shields.io/badge/ABAP-7.58%2B-blue )](https://abaplint.app/stats/greltel/abap-dynamic-assignment/statement_compatibility)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-dynamic-assignment)
[![License](https://img.shields.io/badge/License-MIT-green)](https://github.com/greltel/abap-dynamic-assignment/blob/main/LICENSE)

A lightweight, dynamic runtime parameter framework.
It decouples configuration values from code logic, allowing developers, functional consultants or key users
to maintain variables, ranges and mappings through a Fiori Elements application or a programmatic API,
bypassing hardcoded values and the rigid standard TVARVC table.

# Table of contents
1. [License](#license)
2. [Contributors-Developers](#contributors-developers)
3. [Key Benefits](#key-benefits)
4. [Prerequisites](#prerequisites)
5. [Installation](#installation)
6. [Authorization](#authorization)
7. [Usage](#usage)
8. [The configuration table](#the-configuration-table)
9. [Running the tests](#running-the-tests)
10. [Contributing](#contributing)

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
* **ABAP Cloud:** Written for ABAP for Cloud Development, language version 5.
* **Testable:** The public surface sits behind `ZIF_DA_VARIANTS`, so consumers can mock the framework
  with `cl_abap_testdouble` instead of setting up a database.
* **Unit Tested:** 67 ABAP Unit tests across five test classes, using the OSQL Test Double Framework
  for zero database footprint.
* **Fiori Elements App** built with RAP, including validations, defaults, draft handling and
  authorization checks.

## Prerequisites

* SAP S/4HANA 2023 FPS03 or higher (ABAP 7.58)
* Authorization object `ZDA_VAR` — see [Authorization](#authorization)

## Installation

1. Pull the repository with [abapGit](http://abapgit.org) into a Z package.
2. Create the authorization object **before** activating (the behaviour pool references it).
3. Adjust `ZCL_DA_VARIANTS=>default_packages` to the name of your own package.
   The constructor validates the configuration table against this list and rejects anything outside it.
4. Publish the service binding `ZUI_DA_VARIANTS_O4`.
5. Create the IAM App, Business Catalog and Launchpad tile so that the application reaches your users.

## Authorization

The framework ships an authorization object that the RAP handlers check on every create, update and delete.

**Authorization field** (SU20, or ADT → New → Other ABAP Repository Object → Authorization Field):

| Field | Data element |
|---|---|
| `ZDA_PROG` | `ZDE_DA_PROGNAME` |

**Authorization object** (SU21):

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

> **The DCL protects the Fiori application, not `get_variant`.** The class reads the table directly,
> so a background job is never filtered by the authorizations of a user. That is intentional —
> a scheduled job must not depend on who happens to be logged on.

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
    " error->get_text( ) carries the reason
ENDTRY.
```

> **The constructor can fail.** It validates the configuration table name with
> `cl_abap_dyn_prg=>check_table_name_str`, so it raises `ZCX_DA_VARIANTS` if the table is unknown
> or lives outside the allowed packages. Wrap it in the same `TRY` as the read.

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

`set_variant` rejects a variant that the framework would not be able to read back: an unknown or
non-elementary data element, and `BT` or `NB` without an upper bound. The Fiori application enforces
the same rules through RAP validations.

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

> **Keep the two roles apart.** A mapping row uses `EQ` and leaves `HighValue` empty; the range fields
> have no meaning there. Use separate `Parameterid` values for ranges and for mappings, otherwise the
> same rows get read two different ways and confuse the next reader.

### Injecting your own configuration table

```abap
DATA(variants) = CAST zif_da_variants(
                     NEW zcl_da_variants( table_name = 'ZMY_OWN_VARIANTS'
                                          packages   = 'ZMY_PACKAGE' ) ).
```

The injected table must be **structurally identical** to `ZDA_VARIANTS` and must reside in one of the
listed packages.

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
| `DESCRIPTION` | Free text, generated when left empty |

Administrative fields are filled by the RAP framework and by `set_variant`.

## Running the tests

```
ADT: right click the package -> Run As -> ABAP Unit Test   (Ctrl+Shift+F10)
```

67 tests across five test classes:

| Test class | Covers |
|---|---|
| `ltc_variants` | Ranges, value tables, mapping tables, normalisation, validation, the constructor |
| `ltc_exception` | The dynamic message text of `ZCX_DA_VARIANTS` |
| `ltc_numbering` | Early numbering, including pending drafts |
| `ltc_defaults` | The determination that fills `IsActive`, `Sign` and `Opt` |
| `ltc_validations` | Both save-time validations, triggered through a real save |

Static checks, locally or in CI:

```bash
npm install -g @abaplint/cli
abaplint
```

## Contributing

Pull requests are welcome. Every pull request must pass the abaplint workflow.

New code follows [Clean ABAP](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md):
no Hungarian prefixes, modern strict Open SQL, ABAP Doc on every public declaration, and an ABAP Unit
test for every new behaviour.
