// @ts-check
import { loadOptions } from "easy-nix-documentation/loader";
import { env, exit } from "node:process";

export default {
  async load() {
    const options_json = env["WRAPPER_MANAGER_OPTIONS_JSON"];

    if (options_json === undefined) {
      console.error("WRAPPER_MANAGER_OPTIONS_JSON not set");
      exit(1);
    }

    return await loadOptions(options_json, {
      mapDeclarations: (declaration) => {
        const relDecl = declaration.replace(/.*wrapper-manager\//, "");
        console.log(relDecl);
        return `<a href="http://github.com/viperML/wrapper-manager/tree/master/${relDecl}">&lt;wrapper-manager/${relDecl}&gt;</a>`;
      },
    });
  },
};
