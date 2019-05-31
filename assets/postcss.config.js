const tailwindcss = require('tailwindcss');
const purgecss = require('postcss-purgecss');

const glob = require('glob');
const whitelist = require('./whitelist.js');
const fs = require('fs');

// Locate lib/<app>_web/ to locate .l?eex files
const files = fs.readdirSync('../lib/');
const appWeb = files.filter((file) => file.endsWith("_web"))[0]
const searchPath = '../lib/' + appWeb + '/**/*eex'

class TailwindExtractor {
 static extract(content) {
   return content.match(/[A-Za-z0-9-_:\/]+/g) || [];
 }
}


var plugins =  [
  tailwindcss('./tailwind.js'),
]
const purge = [
    purgecss({
        content: glob.sync(searchPath, { nodir: true }),
        whitelist: whitelist,
        extractors: [
          {
            extractor: TailwindExtractor,
            // Specify the file extensions to include when scanning for
            // class names.
            extensions: ["eex", "leex"]
          }
        ]
    }),
]

if (
      process.argv.includes("development") &&
      process.argv.includes("--mode")
   ) {
  console.log('[postcss] ...dev mode detected, not purging css')
} else if (
      process.argv.includes("production") &&
      process.argv.includes("--mode")   
  ) {
  console.log('[postcss] ...prod mode detected, purging css')
  plugins = plugins.concat(purge)
} else {
  console.log("[postcss] ...no mode detected", {process_argv: process.argv})
}

module.exports = {
    plugins: plugins
}