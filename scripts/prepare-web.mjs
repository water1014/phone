import { cp, mkdir, rm } from "node:fs/promises";
import { existsSync } from "node:fs";

const root = process.cwd();
const out = new URL("../www/", import.meta.url);
const entries = [
  "index.html",
  "icon.svg",
  "sw.js",
  "galaxy.html",
  "css",
  "js",
  "mio",
  "widgets"
];

await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });

for (const entry of entries) {
  const source = new URL("../" + entry, import.meta.url);
  if (!existsSync(source)) {
    if (["index.html", "css", "js", "mio"].includes(entry)) {
      throw new Error("Required web asset is missing: " + entry);
    }
    continue;
  }
  await cp(source, new URL("../www/" + entry, import.meta.url), {
    recursive: true,
    force: true
  });
}

console.log("Prepared phone web assets in www/ for Capacitor.");
