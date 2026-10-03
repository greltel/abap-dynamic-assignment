import { SQLiteDatabaseClient } from "@abaplint/database-sqlite";
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

// An abapGit repository does not carry the name of its root package and the
// transpiler registers every object in TADIR under $TMP. The package this
// repository is installed into on a real system is therefore named here, so
// that cl_abap_dyn_prg=>check_table_name_str can tell own tables from foreign ones.
const rootPackage = "ZDA_DYNAMIC_ASSIGNMENT";
const sourceFolder = path.join(path.dirname(fileURLToPath(import.meta.url)), "src");

export async function setupDatabase(abap, schemas, insert) {
  const client = new SQLiteDatabaseClient();
  abap.context.databaseConnections["DEFAULT"] = client;
  await client.connect();
  await client.execute(schemas.sqlite);
  await client.execute(insert);

  // file names are <object name>.<object type>.<...>, e.g. ztda_variants.tabl.xml
  const objects = new Set(fs.readdirSync(sourceFolder).map(file => file.split(".")[0].toUpperCase()));
  for (const object of objects) {
    await client.execute(`UPDATE tadir SET devclass = '${rootPackage}' WHERE obj_name = '${object}';`);
  }
}
