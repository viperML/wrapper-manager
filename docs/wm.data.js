// @ts-check
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { loadOptions, stripNixStore } from "easy-nix-documentation/loader";
import { env } from "node:process";

const var_name = "WRAPPER_MANAGER_OPTIONS_JSON";

export default {
  async load() {
    const built = env[var_name];
    const settings = {
      mapDeclarations: (declaration) => {
        const relDecl = stripNixStore(declaration);
        return `<a href="http://github.com/viperML/wrapper-manager/tree/master/${relDecl}">&lt;wrapper-manager/${relDecl}&gt;</a>`;
      },
    };
    if (built === undefined) {
      console.log(var_name, "not set, falling back with nix build");
      const __dirname = dirname(fileURLToPath(import.meta.url));
      return await loadOptions(`${__dirname}#optionsJSON`, settings);
    } else {
      return await loadOptions(built, settings);
    }
  },
};
