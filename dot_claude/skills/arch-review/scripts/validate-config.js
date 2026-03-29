#!/usr/bin/env node

/**
 * validate-config.js
 *
 * Validates and resolves the arch-review configuration file.
 *
 * Resolution order:
 *   1. $XDG_CONFIG_HOME/arch-review/config.json (default: ~/.config/arch-review/config.json)
 *   2. <project-root>/.arch-review.json
 *
 * Exit codes:
 *   0 - Valid config found. Prints resolved config JSON to stdout.
 *   1 - No config file found.
 *   2 - Config file found but invalid.
 */

const fs = require("fs");
const path = require("path");

// --- Path resolution ---

function getXdgConfigPath() {
  const xdgHome =
    process.env.XDG_CONFIG_HOME || path.join(require("os").homedir(), ".config");
  return path.join(xdgHome, "arch-review", "config.json");
}

function getProjectConfigPath() {
  // Use CWD as project root
  return path.join(process.cwd(), ".arch-review.json");
}

function resolveConfigPath() {
  const candidates = [getXdgConfigPath(), getProjectConfigPath()];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return null;
}

// --- Validation ---

const LAYER_NAMES = ["domain", "application", "infrastructure", "presentation"];

const OUTPUT_SCHEMAS = {
  file: { required: ["path"], types: { path: "string" } },
  text: { required: [], types: {} },
  shell: { required: ["command"], types: { command: "string" } },
};

function validateLayers(layers, contextPrefix) {
  const errors = [];
  if (typeof layers !== "object" || layers === null || Array.isArray(layers)) {
    errors.push(`${contextPrefix}.layers must be an object`);
    return errors;
  }
  for (const name of LAYER_NAMES) {
    if (!(name in layers)) {
      errors.push(`${contextPrefix}.layers.${name} is required`);
    } else if (typeof layers[name] !== "string") {
      errors.push(`${contextPrefix}.layers.${name} must be a string`);
    }
  }
  const extraKeys = Object.keys(layers).filter((k) => !LAYER_NAMES.includes(k));
  if (extraKeys.length > 0) {
    errors.push(
      `${contextPrefix}.layers has unknown keys: ${extraKeys.join(", ")}`
    );
  }
  return errors;
}

function validateOutputEntry(entry, index) {
  const errors = [];
  const prefix = `output[${index}]`;

  if (typeof entry !== "object" || entry === null || Array.isArray(entry)) {
    errors.push(`${prefix} must be an object`);
    return errors;
  }
  if (!("type" in entry)) {
    errors.push(`${prefix}.type is required`);
    return errors;
  }
  const schema = OUTPUT_SCHEMAS[entry.type];
  if (!schema) {
    errors.push(
      `${prefix}.type must be one of: ${Object.keys(OUTPUT_SCHEMAS).join(", ")} (got "${entry.type}")`
    );
    return errors;
  }
  for (const field of schema.required) {
    if (!(field in entry)) {
      errors.push(`${prefix}.${field} is required for type "${entry.type}"`);
    } else if (typeof entry[field] !== schema.types[field]) {
      errors.push(
        `${prefix}.${field} must be a ${schema.types[field]} (got ${typeof entry[field]})`
      );
    }
  }
  return errors;
}

function validateOutput(output) {
  const errors = [];
  if (!Array.isArray(output)) {
    errors.push("output must be an array");
    return errors;
  }
  if (output.length === 0) {
    errors.push("output must have at least one entry");
    return errors;
  }
  for (let i = 0; i < output.length; i++) {
    errors.push(...validateOutputEntry(output[i], i));
  }
  return errors;
}

function validateConfig(config) {
  const errors = [];

  if (typeof config !== "object" || config === null || Array.isArray(config)) {
    return ["Config must be a JSON object"];
  }

  const hasLayers = "layers" in config;
  const hasModules = "modules" in config;

  if (!hasLayers && !hasModules) {
    errors.push('Config must have either "layers" (flat) or "modules" (monorepo)');
  }
  if (hasLayers && hasModules) {
    errors.push(
      '"layers" and "modules" are mutually exclusive. Use "layers" for flat projects, "modules" for monorepos'
    );
  }

  // Flat mode
  if (hasLayers && !hasModules) {
    errors.push(...validateLayers(config.layers, ""));
  }

  // Monorepo mode
  if (hasModules) {
    if (!Array.isArray(config.modules)) {
      errors.push("modules must be an array");
    } else if (config.modules.length === 0) {
      errors.push("modules must have at least one entry");
    } else {
      for (let i = 0; i < config.modules.length; i++) {
        const mod = config.modules[i];
        const prefix = `modules[${i}]`;
        if (typeof mod !== "object" || mod === null || Array.isArray(mod)) {
          errors.push(`${prefix} must be an object`);
          continue;
        }
        if (!mod.name || typeof mod.name !== "string") {
          errors.push(`${prefix}.name is required and must be a string`);
        }
        if (!mod.root || typeof mod.root !== "string") {
          errors.push(`${prefix}.root is required and must be a string`);
        }
        if (!mod.layers) {
          errors.push(`${prefix}.layers is required`);
        } else {
          errors.push(...validateLayers(mod.layers, prefix));
        }
      }
      // Check duplicate module names
      const names = config.modules
        .filter((m) => m && m.name)
        .map((m) => m.name);
      const dupes = names.filter((n, i) => names.indexOf(n) !== i);
      if (dupes.length > 0) {
        errors.push(`Duplicate module names: ${[...new Set(dupes)].join(", ")}`);
      }
    }
  }

  // Output
  if (!("output" in config)) {
    errors.push("output is required");
  } else {
    errors.push(...validateOutput(config.output));
  }

  return errors;
}

// --- Main ---

function main() {
  const configPath = resolveConfigPath();

  if (!configPath) {
    console.error(
      JSON.stringify({
        ok: false,
        error: "no_config",
        message: "No config file found",
        searched: [getXdgConfigPath(), getProjectConfigPath()],
      })
    );
    process.exit(1);
  }

  let raw;
  try {
    raw = fs.readFileSync(configPath, "utf-8");
  } catch (e) {
    console.error(
      JSON.stringify({
        ok: false,
        error: "read_error",
        message: `Failed to read ${configPath}: ${e.message}`,
        configPath,
      })
    );
    process.exit(2);
  }

  let config;
  try {
    config = JSON.parse(raw);
  } catch (e) {
    console.error(
      JSON.stringify({
        ok: false,
        error: "parse_error",
        message: `Invalid JSON in ${configPath}: ${e.message}`,
        configPath,
      })
    );
    process.exit(2);
  }

  const errors = validateConfig(config);
  if (errors.length > 0) {
    console.error(
      JSON.stringify({
        ok: false,
        error: "validation_error",
        message: `Config validation failed (${errors.length} error(s))`,
        errors,
        configPath,
      })
    );
    process.exit(2);
  }

  // Determine mode
  const mode = "modules" in config ? "monorepo" : "flat";

  console.log(
    JSON.stringify({
      ok: true,
      configPath,
      mode,
      config,
    })
  );
  process.exit(0);
}

main();
