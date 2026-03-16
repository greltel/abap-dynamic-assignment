# ABAP Dynamic Assignment
# ✅ Status: Initial Release (1.0.0)
> **Open Source Contribution:** This project is community-driven and **Open Source**! 🚀  
> If you spot a bug or have an idea for a cool enhancement, your contributions are more than welcome. Feel free to open an **Issue** or submit a **Pull Request**.

[![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)](https://abaplint.app/stats/greltel/abap-dynamic-assignment/object_classifications)
[![ABAP Version](https://img.shields.io/badge/ABAP-7.58%2B-blue )](https://abaplint.app/stats/greltel/abap-dynamic-assignment/statement_compatibility)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-dynamic-assignment)
[![License](https://img.shields.io/badge/License-MIT-green)](https://github.com/greltel/abap-dynamic-assignment/blob/main/LICENSE)

A lightweight, dynamic runtime parameter framework.
It decouples configuration values from code logic, allowing developers,functional consultants or key users to maintain variables, ranges, and mappings via a simple database table ( `SM30`, `Business Configuration`, `RAP Application`), bypassing hardcoded values and the rigid standard TVARVC table.

# Table of contents
1. [License](#License)
2. [Contributors-Developers](#Contributors-Developers)
3. [Key Benefits](#Key-Benefits)
4. [Design Goals-Features](#Design-Goals-Features)
5. [Usage](#Usage)

## License
This project is licensed under the [MIT License](https://github.com/greltel/abap-dynamic-assignment/blob/main/LICENSE).

## Contributors-Developers
The repository was created by [George Drakos](https://www.linkedin.com/in/george-drakos/).

## Key Benefits

* **No more TVARVC:** Forget the limitations, clutter, and rigid structure of the standard SAP TVARVC table.
* **Zero Hardcoding:** Keep your business logic clean. No more `IF bukrs = '1000'` or hardcoded configuration IDs in your programs.
* **Hot-Swap Parameters:** Change program behaviors, inclusion/exclusion rules (Sign I/E), and value mappings in Production without a Transport Request.
* **RTTS:** Automatically generates Single Values, Range Tables (ready for `SELECT ... IN`), and Mapping Tables on the fly using Run Time Type Services.
* **100% ABAP Cloud Ready:** Built with Tier 1 Cloud compatibility.
* **Fully Decoupled:** Works seamlessly with the default `ZDA_VARIANTS` table or **any** custom configuration table you inject into the framework.
* **Unit Tested:** Built-in ABAP Unit tests, utilizing the OSQL Test Double Framework for zero database footprint.
* **Fiori Elements App** built entirely with the ABAP RESTful Application Programming Model (RAP) for maintaining parameter variants.

## Design Goals-Features

* Install via [ABAPGit](http://abapgit.org)
* ABAP Cloud/Clean Core compatibility.Passed SCI check variant S4HANA_READINESS_2023 and ABAP_CLOUD_READINESS
* Unit Tested

## Usage

### In your ABAP Programs / Classes / APIs

1.  Define variables or inline declarations for your target data types (Single Value, Range, or Table).
2.  Instantiate the framework class `ZCL_DA_VARIANTS`.
3.  Call the `get_variant` method to dynamically build your parameters.
4.  Use the generated ranges or values directly in your business logic or OpenSQL statements.

```abap
DATA lv_matnr TYPE matnr.
DATA lr_matnr TYPE RANGE OF matnr.
DATA lt_matnr TYPE STANDARD TABLE OF matnr.

DATA(lo_variants) = NEW zcl_da_variants( ).

TRY.
    lo_variants->get_variant(
      EXPORTING
        im_parameterid  = 'VALID_MATERIALS'
        im_progname     = 'GLOBAL' 
      IMPORTING
        ex_fieldvalue   = lv_matnr          " Gets the single value
        ex_range        = lr_matnr          " Gets the dynamically built Range Table
        ex_table_values = lt_matnr          " Gets a standard table of values
    ).

    SELECT FROM mara
      FIELDS *
      WHERE matnr IN @lr_matnr 
         OR matnr EQ @lv_matnr
      INTO TABLE @DATA(lt_mara).

  CATCH zcx_da_variants INTO DATA(lx_error).
    out->write( lx_error->get_text( ) ).
ENDTRY.
```

### Creating Variants Programmatically

You can also use the framework to programmatically create or update variants (e.g., for Initial Data Load scripts, Seed Data, or API integrations) using the `set_variant` method. 

1.  Instantiate the framework class `ZCL_DA_VARIANTS`.
2.  Call the `set_variant` method with your target values.
3.  Use the provided Class Constants (ENUMs) when passing `SIGN` and `OPTION` values.
4.  Handle the custom exception to catch any validation errors.

```abap
DATA(lo_variants) = NEW zcl_da_variants( ).

TRY.
    lo_variants->set_variant(
      EXPORTING
        im_parameterid  = 'DEFAULT_PLANTS'
        im_progname     = 'ZTEST'
        im_fieldvalue   = '1000'
        im_high_value   = '2000'
        im_sign         = zcl_da_variants=>sign_include
        im_opt          = zcl_da_variants=>opt_bt
        im_description  = 'Default Plant for Operations'
    ).
  CATCH zcx_da_variants INTO DATA(lx_error).
    out->write( lx_error->get_text( ) ).
ENDTRY.
```
