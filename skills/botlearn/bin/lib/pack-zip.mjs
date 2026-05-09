#!/usr/bin/env node
/**
 * pack-zip.mjs — Pure Node zip writer (no external dependencies).
 *
 * Usage:
 *   node pack-zip.mjs <src-dir> <out-file>
 *
 * Behavior mirrors lib/community/skill-upload/constants.ts so the archive
 * passes server-side validation without surprise rejections:
 *   - Excludes node_modules, .git, __pycache__, .venv, dist, build, .next, etc.
 *   - Skips .DS_Store, Thumbs.db, lock files
 *   - Allows only whitelisted extensions for known text/config files
 *   - Enforces MAX_FILE_COUNT=100, MAX_SINGLE_FILE_SIZE=500 KB, MAX_TOTAL_SIZE=5 MB
 *   - DEFLATE compression via zlib.deflateRawSync
 *
 * Output is a standards-compliant ZIP (local file headers + central directory
 * + EOCD record) readable by unzip, yauzl, or the server's extractor.
 *
 * Exit codes:
 *   0 — success, printed JSON summary: { path, size, fileCount, totalUncompressed }
 *   1 — validation failure (details on stderr)
 *   2 — IO or internal error
 */

import { readdirSync, readFileSync, writeFileSync, statSync } from 'node:fs'
import { join, relative, sep } from 'node:path'
import * as zlib from 'node:zlib'

const { deflateRawSync } = zlib

// zlib.crc32 requires Node 22+; fall back to a table-based implementation on older runtimes.
const crc32 = typeof zlib.crc32 === 'function' ? zlib.crc32 : buildCrc32Fallback()

function buildCrc32Fallback() {
  const table = new Uint32Array(256)
  for (let i = 0; i < 256; i++) {
    let c = i
    for (let k = 0; k < 8; k++) {
      c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1)
    }
    table[i] = c >>> 0
  }
  return function crc32(buf) {
    let c = 0xffffffff
    for (let i = 0; i < buf.length; i++) {
      c = table[(c ^ buf[i]) & 0xff] ^ (c >>> 8)
    }
    return (c ^ 0xffffffff) >>> 0
  }
}

const MAX_ARCHIVE_FILES = 100
const MAX_SINGLE_FILE = 500 * 1024
const MAX_TOTAL_UNCOMPRESSED = 5 * 1024 * 1024

const ALLOWED_EXT = new Set([
  '.md', '.txt', '.json', '.yaml', '.yml', '.toml',
  '.py', '.js', '.ts', '.sh', '.bash', '.zsh',
  '.cfg', '.conf', '.ini',
  '.html', '.css', '.scss',
])

const EXCLUDED_DIRS = new Set([
  'node_modules', '.git', '__pycache__', '.venv', 'venv',
  '.idea', '.vscode', '.pytest_cache', '.mypy_cache',
  'dist', 'build', '.next', '.nuxt',
])

const EXCLUDED_FILES = new Set([
  '.DS_Store', 'Thumbs.db', '.gitignore', '.npmrc',
  'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml',
])

function die(msg, code = 1) {
  process.stderr.write(`pack-zip: ${msg}\n`)
  process.exit(code)
}

function extOf(name) {
  const idx = name.lastIndexOf('.')
  return idx < 0 ? '' : name.slice(idx).toLowerCase()
}

function walk(root) {
  const out = []
  function visit(dir) {
    let entries
    try {
      entries = readdirSync(dir, { withFileTypes: true })
    } catch (err) {
      die(`cannot read directory ${dir}: ${err.message}`, 2)
    }
    for (const ent of entries) {
      const abs = join(dir, ent.name)
      if (ent.isDirectory()) {
        if (EXCLUDED_DIRS.has(ent.name)) continue
        visit(abs)
      } else if (ent.isFile()) {
        if (EXCLUDED_FILES.has(ent.name)) continue
        const rel = relative(root, abs).split(sep).join('/')
        if (!ALLOWED_EXT.has(extOf(ent.name))) continue
        out.push({ abs, rel })
      }
    }
  }
  visit(root)
  return out.sort((a, b) => a.rel.localeCompare(b.rel))
}

function dosDateTime(d) {
  const time = ((d.getHours() & 0x1f) << 11) | ((d.getMinutes() & 0x3f) << 5) | ((Math.floor(d.getSeconds() / 2)) & 0x1f)
  const year = Math.max(0, d.getFullYear() - 1980)
  const date = ((year & 0x7f) << 9) | (((d.getMonth() + 1) & 0x0f) << 5) | (d.getDate() & 0x1f)
  return { time, date }
}

function buildZip(files) {
  const now = new Date()
  const { time, date } = dosDateTime(now)
  const localChunks = []
  const centralChunks = []
  let offset = 0
  let fileCount = 0

  for (const f of files) {
    const nameBuf = Buffer.from(f.rel, 'utf8')
    const rawCrc = crc32(f.content)
    const compressed = deflateRawSync(f.content)
    const useDeflate = compressed.length < f.content.length
    const dataBuf = useDeflate ? compressed : f.content
    const method = useDeflate ? 8 : 0

    const local = Buffer.alloc(30)
    local.writeUInt32LE(0x04034b50, 0)
    local.writeUInt16LE(20, 4)
    local.writeUInt16LE(0x0800, 6) // UTF-8 flag
    local.writeUInt16LE(method, 8)
    local.writeUInt16LE(time, 10)
    local.writeUInt16LE(date, 12)
    local.writeUInt32LE(rawCrc, 14)
    local.writeUInt32LE(dataBuf.length, 18)
    local.writeUInt32LE(f.content.length, 22)
    local.writeUInt16LE(nameBuf.length, 26)
    local.writeUInt16LE(0, 28)
    localChunks.push(local, nameBuf, dataBuf)

    const central = Buffer.alloc(46)
    central.writeUInt32LE(0x02014b50, 0)
    central.writeUInt16LE(20, 4)
    central.writeUInt16LE(20, 6)
    central.writeUInt16LE(0x0800, 8)
    central.writeUInt16LE(method, 10)
    central.writeUInt16LE(time, 12)
    central.writeUInt16LE(date, 14)
    central.writeUInt32LE(rawCrc, 16)
    central.writeUInt32LE(dataBuf.length, 20)
    central.writeUInt32LE(f.content.length, 24)
    central.writeUInt16LE(nameBuf.length, 28)
    central.writeUInt16LE(0, 30)
    central.writeUInt16LE(0, 32)
    central.writeUInt16LE(0, 34)
    central.writeUInt16LE(0, 36)
    central.writeUInt32LE(0, 38)
    central.writeUInt32LE(offset, 42)
    centralChunks.push(central, nameBuf)

    offset += local.length + nameBuf.length + dataBuf.length
    fileCount += 1
  }

  const centralStart = offset
  const centralBuf = Buffer.concat(centralChunks)
  const centralSize = centralBuf.length

  const eocd = Buffer.alloc(22)
  eocd.writeUInt32LE(0x06054b50, 0)
  eocd.writeUInt16LE(0, 4)
  eocd.writeUInt16LE(0, 6)
  eocd.writeUInt16LE(fileCount, 8)
  eocd.writeUInt16LE(fileCount, 10)
  eocd.writeUInt32LE(centralSize, 12)
  eocd.writeUInt32LE(centralStart, 16)
  eocd.writeUInt16LE(0, 20)

  return Buffer.concat([...localChunks, centralBuf, eocd])
}

function main() {
  const [src, out] = process.argv.slice(2)
  if (!src || !out) die('usage: pack-zip.mjs <src-dir> <out-file>', 2)

  let stats
  try {
    stats = statSync(src)
  } catch (err) {
    die(`source not found: ${src}`, 2)
  }
  if (!stats.isDirectory()) die(`source is not a directory: ${src}`, 2)

  const listed = walk(src)
  if (listed.length === 0) die('no packable files found (SKILL.md missing or all files filtered)')
  if (listed.length > MAX_ARCHIVE_FILES) die(`too many files: ${listed.length} > ${MAX_ARCHIVE_FILES}`)

  const files = []
  let totalBytes = 0
  let hasSkillMd = false

  for (const entry of listed) {
    let content
    try {
      content = readFileSync(entry.abs)
    } catch (err) {
      die(`cannot read ${entry.rel}: ${err.message}`, 2)
    }
    if (content.length > MAX_SINGLE_FILE) {
      die(`file too large: ${entry.rel} is ${content.length} bytes > ${MAX_SINGLE_FILE}`)
    }
    totalBytes += content.length
    if (totalBytes > MAX_TOTAL_UNCOMPRESSED) {
      die(`total uncompressed size exceeds ${MAX_TOTAL_UNCOMPRESSED} bytes`)
    }
    if (entry.rel === 'SKILL.md') hasSkillMd = true
    files.push({ rel: entry.rel, content })
  }

  if (!hasSkillMd) die('SKILL.md not found at archive root')

  const zipBuf = buildZip(files)
  try {
    writeFileSync(out, zipBuf)
  } catch (err) {
    die(`cannot write ${out}: ${err.message}`, 2)
  }

  process.stdout.write(JSON.stringify({
    path: out,
    size: zipBuf.length,
    fileCount: files.length,
    totalUncompressed: totalBytes,
  }))
}

main()
