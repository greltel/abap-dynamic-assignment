# ABAP Dynamic Assignment
# ✅ Status: Initial Release (1.0.0)
> **Open Source Contribution:** This project is community-driven and **Open Source**! 🚀  
> If you spot a bug or have an idea for a cool enhancement, your contributions are more than welcome. Feel free to open an **Issue** or submit a **Pull Request**.

[![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)](https://abaplint.app/stats/greltel/abap-dynamic-assignment/object_classifications)
[![ABAP Version](https://img.shields.io/badge/ABAP-7.54%2B-blue )](https://abaplint.app/stats/greltel/abap-dynamic-assignment/statement_compatibility)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-dynamic-assignment)
[![License](https://img.shields.io/badge/License-MIT-green)](https://github.com/greltel/abap-dynamic-assignment/blob/main/LICENSE)
![Version](https://img.shields.io/endpoint?url=https://shield.abappm.com/github/greltel/abap-dynamic-assignment/src/zcl_form_translation.clas.abap/c_version)

A lightweight, dynamic **runtime translation tool** for SAP forms.
It decouples text management from form development, allowing functional consultants or users to maintain labels via a simple database table (`SM30`,`Business Configuration`,`RAP Application`), bypassing the complex standard SE63 workflow.

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

### In your Adobe / Smartform Driver Program / Print Program

1.  Define a structure for your labels/texts in the form Global Definitions or the Driver Program.
2.  Populate it with default values (optional).
3.  Call the translator **before** calling the form Function Module(for smartforms).

```abap
DATA: BEGIN OF gs_labels,
        title        TYPE string,
        footer_note  TYPE string,
        customer_lbl TYPE string,
      END OF gs_labels.

" 1.Initialize (Optional defaults)
gs_labels-title = 'Invoice'.

" 2.Translate dynamically based on Language and DB Configuration
NEW zcl_form_translation( )->translate_form(
  EXPORTING
    iv_formname      = 'ZINVOICE_FORM'   " Key in ZABAP_FORM_TRANS
    iv_langu         = p_langu           " e.g., NAST-SPRAS
  CHANGING
    cs_form_elements = gs_labels ).         " The structure to be translated

" 3. The gs_labels structure now contains the translated texts from ZDB_FORM_TRANS
"    Pass this structure to your Smartform / Adobe Form interface.

