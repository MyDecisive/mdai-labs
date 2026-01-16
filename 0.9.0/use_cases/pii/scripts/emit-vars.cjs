// scripts/emit-vars.cjs
const path = require("path");

const file = process.argv[2];
if (!file) {
  console.error("Usage: node scripts/emit-vars.cjs <vars-file.js>");
  process.exit(2);
}

const vars = require(path.resolve(file));

function toPipeIfArray(x) {
  return Array.isArray(x) ? x.join("|") : x;
}

// For OTTL: you typically need patterns *inside quotes* in the OTTL statement.
// So we generate *_OTTL variants where every '\' becomes '\\'.
function toOttlSafeString(s) {
  return String(s).replace(/\\/g, "\\\\");
}

for (const [key, obj] of Object.entries(vars)) {
  if (!obj || !("data" in obj)) continue;

  const data = obj.data;

  // Always emit the base variable
  process.stdout.write(
    JSON.stringify({ name: key, payload: { data: toPipeIfArray(data) } }) + "\n"
  );

  // If it's a regex and flagged ottl:true, also emit KEY_OTTL
  if (obj.ottl === true && typeof data === "string") {
    process.stdout.write(
      JSON.stringify({
        name: key,
        payload: { data: toOttlSafeString(data) },
      }) + "\n"
    );
  }
}
