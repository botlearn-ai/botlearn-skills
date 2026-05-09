# BotLearn CLI — Solutions & Marketplace commands
# Sourced by botlearn.sh — do not run directly

cmd_install() {
  local skill_name="${1:?Usage: botlearn.sh skillhunt <skill_name> [recommendation_id] [session_id]}"
  local rec_id="${2:-}"
  local sess_id="${3:-}"
  _install_tmp=""
  trap 'rm -f "${_install_tmp:-}" 2>/dev/null' EXIT INT TERM

  echo "🔍 Skill Hunt — installing $skill_name..."

  # ── Step 1: Fetch skill info ──
  info "├─ Fetching skill details..."
  local skill_json
  local encoded_name
  encoded_name=$(urlencode "$skill_name")
  skill_json=$(api GET "/api/v2/skills/by-name?name=$encoded_name") || die "Failed to fetch skill info for: $skill_name"

  # ── Step 2: Parse skill metadata ──
  local parsed
  parsed=$(echo "$skill_json" | node -e "
const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
  try{
    const r=JSON.parse(Buffer.concat(d).toString());
    const s=r.success?r.data:r;
    process.stdout.write(JSON.stringify({
      archiveUrl:s.latestArchiveUrl||'',
      version:s.version||'unknown',
      name:s.name||'$skill_name',
      displayName:s.displayName||s.name||'$skill_name',
      description:(s.description||'').substring(0,120),
      fileCount:(s.fileIndex||[]).length
    }));
  }catch(e){process.stderr.write('parse error: '+e.message);process.exit(1)}
})") || die "Failed to parse skill info response"

  # Extract all fields in a single node call (tab-separated)
  local archive_url version skill_display_name skill_desc file_count resolved_name
  local _fields
  _fields=$(echo "$parsed" | node -e "
    const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
      const o=JSON.parse(Buffer.concat(d).toString());
      process.stdout.write([o.archiveUrl||'',o.version||'unknown',o.displayName||o.name||'',o.description||'',String(o.fileCount||0),o.name||''].join('\t'));
    })" 2>/dev/null) || true
  IFS=$'\t' read -r archive_url version skill_display_name skill_desc file_count resolved_name <<< "$_fields"
  # Use the server-resolved name (DB name) for install registration; fall back to CLI arg
  [ -z "$resolved_name" ] && resolved_name="$skill_name"

  # ── Compute flat install directory name ──
  # OpenClaw / Claude Code require skills under skills/{skill_name}/ — never
  # skills/{owner}/{skill_name}/. Strip any owner/ prefix and auto-rename on
  # collision so an existing directory is never overwritten.
  local dir_name="${resolved_name##*/}"
  [ -z "$dir_name" ] && dir_name="${skill_name##*/}"
  local base_dir_name="$dir_name"
  if [ -d "$WORKSPACE/skills/$dir_name" ] && [ -n "$(ls -A "$WORKSPACE/skills/$dir_name" 2>/dev/null)" ]; then
    local suffix=2
    while [ -d "$WORKSPACE/skills/${base_dir_name}-${suffix}" ] && [ -n "$(ls -A "$WORKSPACE/skills/${base_dir_name}-${suffix}" 2>/dev/null)" ]; do
      suffix=$((suffix + 1))
    done
    dir_name="${base_dir_name}-${suffix}"
    info "├─ skills/${base_dir_name}/ already exists — installing as skills/${dir_name}/"
  fi

  echo "  📦 $skill_display_name v$version"
  echo "     $skill_desc"
  echo "     Files: $file_count"

  # ── Step 3: Download archive ──
  local target_dir=""
  if [ -z "$archive_url" ]; then
    echo "  ⚠️  No archive available for this skill — no files will be downloaded."
    echo "     The skill may not have published an installable package yet."
    echo "     Registering install record only."
  else
    target_dir="$WORKSPACE/skills/$dir_name"
    local tmp_archive
    tmp_archive=$(mktemp); _install_tmp="$tmp_archive"

    info "├─ Downloading archive..."
    curl -sL --connect-timeout 10 --max-time 120 -o "$tmp_archive" "$archive_url" 2>/dev/null || {
      rm -f "$tmp_archive"
      die "Failed to download skill archive from: $archive_url"
    }

    # Check download is non-empty
    local archive_size
    archive_size=$(wc -c < "$tmp_archive" 2>/dev/null | tr -d ' ')
    if [ "$archive_size" -lt 10 ] 2>/dev/null; then
      rm -f "$tmp_archive"
      die "Downloaded archive is empty or too small ($archive_size bytes)"
    fi

    # ── Step 4: Extract archive ──
    info "├─ Extracting to $target_dir..."
    mkdir -p "$target_dir"

    # Format inferred from URL suffix; extract_archive falls back to tar.gz/zip
    # when unknown, and to python3/python when native unzip/tar is missing.
    local fmt="unknown"
    case "$archive_url" in
      *.tar.gz|*.tgz) fmt="tar.gz" ;;
      *.tar.bz2)      fmt="tar.bz2" ;;
      *.tar)           fmt="tar" ;;
      *.zip)           fmt="zip" ;;
    esac

    if extract_archive "$tmp_archive" "$target_dir" "$fmt"; then
      rm -f "$tmp_archive"
      ok "Files extracted to skills/$dir_name/"
    else
      rm -f "$tmp_archive"
      rm -rf "$target_dir"
      die "Failed to extract archive — see hint above (skill: $resolved_name)"
    fi
  fi

  # ── Step 5: Register installation with server ──
  info "├─ Registering install..."
  local body="{\"name\":\"$(json_str "$resolved_name")\",\"source\":\"benchmark\""
  [ -n "$rec_id" ] && body+=",\"recommendationId\":\"$(json_str "$rec_id")\""
  [ -n "$sess_id" ] && body+=",\"sessionId\":\"$(json_str "$sess_id")\""

  # Detect platform
  local platform
  platform=$(detect_platform)
  body+=",\"platform\":\"$(json_str "$platform")\""
  body+=",\"version\":\"$(json_str "$version")\""
  body+="}"

  local result
  result=$(api POST "/api/v2/skills/by-name/install" "$body")

  # Extract installId from response
  local install_id
  install_id=$(echo "$result" | grep -o '"installId"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')

  # ── Step 6: Update local state.json ──
  if [ -f "$STATE_FILE" ]; then
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

    # Write install record to state.json (pass values via env to avoid JS injection)
    BOTLEARN_STATE_FILE="$STATE_FILE" \
    BOTLEARN_SKILL_NAME="$resolved_name" \
    BOTLEARN_DIR_NAME="$dir_name" \
    BOTLEARN_VERSION="$version" \
    BOTLEARN_INSTALL_ID="$install_id" \
    BOTLEARN_NOW="$now" \
    node -e "
const fs=require('fs');
const {BOTLEARN_STATE_FILE:f,BOTLEARN_SKILL_NAME:name,BOTLEARN_DIR_NAME:dir,BOTLEARN_VERSION:ver,BOTLEARN_INSTALL_ID:iid,BOTLEARN_NOW:now}=process.env;
const state=JSON.parse(fs.readFileSync(f,'utf8'));
if(!state.solutions)state.solutions={};
if(!state.solutions.installed)state.solutions.installed=[];
state.solutions.installed=state.solutions.installed.filter(x=>x.name!==name&&x.dirName!==dir);
state.solutions.installed.push({name,dirName:dir,version:ver,installId:iid,installedAt:now,source:'benchmark',trialStatus:'pending'});
fs.writeFileSync(f,JSON.stringify(state,null,2)+'\n');
" 2>/dev/null
  fi

  ok "Skill installed: $resolved_name v$version"
  if [ -n "$install_id" ]; then
    info "  installId: $install_id"
  fi

  # ── Step 7: Point agent at SKILL.md for initialization ──
  if [ -n "$target_dir" ] && [ -d "$target_dir" ]; then
    local skill_md=""
    if [ -f "$target_dir/SKILL.md" ]; then
      skill_md="$target_dir/SKILL.md"
    elif [ -f "$target_dir/skill.md" ]; then
      skill_md="$target_dir/skill.md"
    else
      # Archive may have a single top-level folder — look one level deep.
      local nested
      nested=$(find "$target_dir" -maxdepth 2 \( -iname "SKILL.md" -o -iname "skill.md" \) -type f 2>/dev/null | head -1)
      [ -n "$nested" ] && skill_md="$nested"
    fi

    echo ""
    echo "  📖 Next: read the skill's SKILL.md and perform any required initialization."
    if [ -n "$skill_md" ]; then
      echo "     File: $skill_md"
    else
      echo "     (No SKILL.md found at skills/$dir_name/ — inspect the directory for usage notes.)"
    fi
    echo "     Look for sections like 'Setup', 'Prerequisites', 'Configuration', or"
    echo "     'Before first use'. Common init work: exporting env vars, OAuth login,"
    echo "     writing a config file, or running a one-time CLI login."
    echo "     Execute any required init steps BEFORE invoking the skill."
  fi

  echo ""
  echo "  💡 Then verify and report:"
  echo "     botlearn.sh run-report $resolved_name $install_id <success|failure> [duration_ms] [tokens]"
}

cmd_uninstall() {
  local skill_name="${1:?Usage: botlearn.sh uninstall <skill_name> [--keep-files]}"
  shift
  local keep_files=0
  for arg in "$@"; do
    case "$arg" in
      --keep-files) keep_files=1 ;;
      *) die "Unknown flag: $arg (supported: --keep-files)" ;;
    esac
  done

  echo "🗑  Uninstalling $skill_name..."

  # ── Step 1: Look up local install record (best-effort; not required) ──
  local dir_name="" install_id="" resolved_name="$skill_name"
  if [ -f "$STATE_FILE" ]; then
    local _record
    _record=$(BOTLEARN_STATE_FILE="$STATE_FILE" BOTLEARN_SKILL_NAME="$skill_name" node -e "
const fs=require('fs');
const {BOTLEARN_STATE_FILE:f,BOTLEARN_SKILL_NAME:q}=process.env;
try{
  const s=JSON.parse(fs.readFileSync(f,'utf8'));
  const list=(s.solutions&&s.solutions.installed)||[];
  const short=q.split('/').pop();
  const hit=list.find(x=>x.name===q||x.name===short||x.dirName===q||x.dirName===short);
  if(hit)process.stdout.write([hit.name||'',hit.dirName||'',hit.installId||''].join('\t'));
}catch(e){}
    " 2>/dev/null) || true
    if [ -n "$_record" ]; then
      IFS=$'\t' read -r resolved_name dir_name install_id <<< "$_record"
      [ -z "$resolved_name" ] && resolved_name="$skill_name"
    fi
  fi

  # ── Step 2: Call server (source of truth, even if local state is missing) ──
  info "├─ Unregistering install with server..."
  local encoded_name
  encoded_name=$(urlencode_path "$resolved_name")
  api DELETE "/api/v2/skills/$encoded_name/install" >/dev/null || die "Failed to unregister install on server"
  ok "Install record removed"

  # ── Step 3: Remove local files (unless --keep-files) ──
  if [ "$keep_files" -eq 1 ]; then
    info "├─ Keeping local files (--keep-files)"
  else
    local removed=0
    if [ -n "$dir_name" ] && [ -d "$WORKSPACE/skills/$dir_name" ]; then
      rm -rf "$WORKSPACE/skills/$dir_name"
      ok "Removed skills/$dir_name/"
      removed=1
    else
      # Fallback: try skills/{short_name}/ (strips any owner/ prefix)
      local short="${resolved_name##*/}"
      if [ -n "$short" ] && [ -d "$WORKSPACE/skills/$short" ]; then
        rm -rf "$WORKSPACE/skills/$short"
        ok "Removed skills/$short/"
        removed=1
      fi
    fi
    [ "$removed" -eq 0 ] && info "  (No local files found to remove)"
  fi

  # ── Step 4: Prune state.json ──
  if [ -f "$STATE_FILE" ]; then
    BOTLEARN_STATE_FILE="$STATE_FILE" \
    BOTLEARN_SKILL_NAME="$resolved_name" \
    BOTLEARN_DIR_NAME="$dir_name" \
    node -e "
const fs=require('fs');
const {BOTLEARN_STATE_FILE:f,BOTLEARN_SKILL_NAME:name,BOTLEARN_DIR_NAME:dir}=process.env;
try{
  const s=JSON.parse(fs.readFileSync(f,'utf8'));
  if(s.solutions&&Array.isArray(s.solutions.installed)){
    const before=s.solutions.installed.length;
    s.solutions.installed=s.solutions.installed.filter(x=>{
      if(x.name===name)return false;
      if(dir&&x.dirName===dir)return false;
      return true;
    });
    if(s.solutions.installed.length!==before){
      fs.writeFileSync(f,JSON.stringify(s,null,2)+'\n');
    }
  }
}catch(e){}
    " 2>/dev/null || true
  fi

  ok "Skill uninstalled: $resolved_name"
  [ -n "$install_id" ] && info "  (was installId: $install_id)"
}

cmd_run_report() {
  local skill_name="${1:?Usage: botlearn.sh run-report <skill_name> <install_id> <status> [duration_ms] [tokens_used]}"
  local install_id="${2:?Missing install_id}"
  local status="${3:?Missing status (success|failure|timeout|error)}"
  local duration="${4:-}"
  local tokens="${5:-}"

  local body="{\"installId\":\"$(json_str "$install_id")\",\"status\":\"$(json_str "$status")\""
  [ -n "$duration" ] && body+=",\"durationMs\":$duration"
  [ -n "$tokens" ] && body+=",\"tokensUsed\":$tokens"
  body+="}"

  api POST "/solutions/$(urlencode_path "$skill_name")/run" "$body" > /dev/null 2>&1
  # Silent — background operation
}

# ── Solutions: Marketplace ──

cmd_skill_info() {
  local name="${1:?Usage: botlearn.sh skill-info <name>}"
  api GET "/api/v2/skills/by-name?name=$(urlencode "$name")"
}

cmd_marketplace() {
  local type="${1:-trending}"
  case "$type" in
    trending)  api GET "/api/v2/skills/trending" ;;
    featured)  api GET "/api/v2/skills/featured" ;;
    *)         die "Unknown type: $type. Use: trending, featured" ;;
  esac
}

cmd_marketplace_search() {
  local query="${1:?Usage: botlearn.sh marketplace-search <query>}"
  local encoded
  encoded=$(urlencode "$query")
  api GET "/api/v2/skills/search?q=$encoded"
}

cmd_skillhunt_search() {
  local query="${1:?Usage: botlearn.sh skillhunt-search <query> [limit] [sort]}"
  local limit="${2:-10}"
  local sort="${3:-relevance}"
  local encoded
  encoded=$(urlencode "$query")

  echo "🔍 SkillHunt Search: \"$query\" (top $limit, sorted by $sort)"
  echo "──────────────────────────────────────────────────────"

  local result
  result=$(api GET "/api/v2/skills/search?q=$encoded&limit=$limit&sort=$sort")

  # Parse and format results
  echo "$result" | node -e "
const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
  try{
    const r=JSON.parse(Buffer.concat(d).toString());
    const data=r.success?r.data:r;
    const skills=data.skills||[];
    const total=data.total||0;

    if(skills.length===0){
      console.log('  No skills found for \"$query\".');
      console.log('  Try different keywords or use: botlearn.sh marketplace trending');
      return;
    }

    console.log('  Found '+total+' skill(s):');
    console.log('');

    skills.forEach((s,i)=>{
      const num=String(i+1).padStart(2,' ');
      const name=s.name||'unknown';
      const display=s.displayName||s.name||'';
      const desc=(s.description||'').substring(0,80);
      const rating=s.ratingAvg?s.ratingAvg.toFixed(1):'—';
      const installs=s.installCount||0;
      const cat=s.category||'';

      console.log('  '+num+'. \\x1b[1m'+name+'\\x1b[0m'+(display&&display!==name?' ('+display+')':''));
      console.log('     '+desc+(desc.length>=80?'...':'')+' · ⭐ '+rating+' · 📦 '+installs+' installs'+(cat?' · '+cat:''));
    });

    console.log('');
    console.log('  💡 Install with: botlearn.sh skillhunt <name>');
  }catch(e){
    console.log('  Failed to parse results.');
    process.stderr.write('parse error: '+e.message);
  }
});" 2>/dev/null || echo "  Failed to format results. Raw response:" && echo "$result"
}

# Download and extract a skill without registering the install.
# Useful for previewing skill contents before committing.
cmd_skill_download() {
  local skill_name="${1:?Usage: botlearn.sh skill-download <skill_name>}"
  local explicit_target="${2:-}"
  local _dl_tmp=""
  trap 'rm -f "$_dl_tmp" 2>/dev/null' EXIT INT TERM

  echo "⬇️  Downloading skill: $skill_name"

  # Fetch skill info
  local skill_json
  skill_json=$(api GET "/api/v2/skills/by-name?name=$(urlencode "$skill_name")") || die "Failed to fetch skill info"

  # Parse archive URL, version, and resolved name in a single node call
  local archive_url version resolved_name
  local _dl_fields
  _dl_fields=$(echo "$skill_json" | node -e "
    const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
      try{const r=JSON.parse(Buffer.concat(d).toString());const s=r.success?r.data:r;
        process.stdout.write((s.latestArchiveUrl||'')+'\t'+(s.version||'unknown')+'\t'+(s.name||''));
      }catch(e){process.exit(1)}
    })" 2>/dev/null) || die "Failed to parse skill info"
  IFS=$'\t' read -r archive_url version resolved_name <<< "$_dl_fields"

  if [ -z "$archive_url" ]; then
    die "No archive available for: $skill_name"
  fi

  # Compute flat target dir (strip owner/ prefix, auto-rename on collision) —
  # unless the caller passed an explicit path as arg 2.
  local target_dir
  if [ -n "$explicit_target" ]; then
    target_dir="$explicit_target"
  else
    local dir_name="${resolved_name:-$skill_name}"
    dir_name="${dir_name##*/}"
    local base_dir_name="$dir_name"
    if [ -d "$WORKSPACE/skills/$dir_name" ] && [ -n "$(ls -A "$WORKSPACE/skills/$dir_name" 2>/dev/null)" ]; then
      local suffix=2
      while [ -d "$WORKSPACE/skills/${base_dir_name}-${suffix}" ] && [ -n "$(ls -A "$WORKSPACE/skills/${base_dir_name}-${suffix}" 2>/dev/null)" ]; do
        suffix=$((suffix + 1))
      done
      dir_name="${base_dir_name}-${suffix}"
      info "├─ skills/${base_dir_name}/ already exists — downloading to skills/${dir_name}/"
    fi
    target_dir="$WORKSPACE/skills/$dir_name"
  fi

  # Download
  local tmp_archive
  tmp_archive=$(mktemp); _dl_tmp="$tmp_archive"
  info "├─ Downloading v${version}..."
  curl -sL --connect-timeout 10 --max-time 120 -o "$tmp_archive" "$archive_url" 2>/dev/null || {
    rm -f "$tmp_archive"
    die "Download failed"
  }

  # Extract — uses shared extract_archive helper (native → python3 → python).
  mkdir -p "$target_dir"
  info "├─ Extracting to $target_dir..."

  local fmt="unknown"
  case "$archive_url" in
    *.tar.gz|*.tgz) fmt="tar.gz" ;;
    *.tar.bz2)      fmt="tar.bz2" ;;
    *.tar)           fmt="tar" ;;
    *.zip)           fmt="zip" ;;
  esac

  if extract_archive "$tmp_archive" "$target_dir" "$fmt"; then
    rm -f "$tmp_archive"
  else
    rm -f "$tmp_archive"
    rm -rf "$target_dir"
    die "Extraction failed — see hint above"
  fi

  ok "Downloaded to $target_dir"
  echo "  ℹ️  This is a preview download only — not registered as an install."
  echo "  Use 'botlearn.sh install $skill_name' to register the install."
}

# ── Solutions: Publishing ──

_pack_zip_script() {
  # Print the path to the pack-zip.mjs helper, sourced relative to this file.
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s' "$here/pack-zip.mjs"
}

# Parse --flag=value style args into variables. Writes to $_flags assoc-like
# via a predictable convention: each "--key=val" becomes _flag_key=val.
# Remaining positional args are kept in the global array _positional.
_parse_flags() {
  _positional=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --*=*)
        local kv="${1#--}"
        local key="${kv%%=*}"
        local val="${kv#*=}"
        # Normalize dashes to underscores for variable names
        key="${key//-/_}"
        eval "_flag_${key}=\$(printf '%s' \"\$val\")"
        ;;
      --*)
        local key="${1#--}"
        key="${key//-/_}"
        eval "_flag_${key}=1"
        ;;
      *)
        _positional+=("$1")
        ;;
    esac
    shift
  done
}

_flag() {
  # Usage: _flag <key>  (echoes value or empty)
  local name="_flag_$1"
  printf '%s' "${!name-}"
}

# Read frontmatter field from a SKILL.md file. Minimal YAML parser:
# matches top-level `key: value` or `key: [a, b, c]` inside the first `---`
# block. For missing fields, prints empty.
_read_skill_md_field() {
  local file="$1" key="$2"
  [ -f "$file" ] || { printf ''; return; }
  SKILL_MD_FILE="$file" SKILL_MD_KEY="$key" node -e "
    const fs=require('fs');
    const src=fs.readFileSync(process.env.SKILL_MD_FILE,'utf8');
    const m=src.match(/^---\\s*\\n([\\s\\S]*?)\\n---/);
    if(!m){process.exit(0)}
    const body=m[1];
    const key=process.env.SKILL_MD_KEY;
    const re=new RegExp('^'+key.replace(/[.*+?^\${}()|[\\]\\\\]/g,'\\\\\$&')+'\\\\s*:\\\\s*(.*)\$','m');
    const mm=body.match(re);
    if(!mm){process.exit(0)}
    let v=mm[1].trim();
    // Strip surrounding quotes
    v=v.replace(/^['\"]|['\"]\$/g,'');
    process.stdout.write(v);
  " 2>/dev/null || true
}

cmd_skill_check_name() {
  local name="${1:?Usage: botlearn.sh skill-check-name <slug>}"
  local encoded
  encoded=$(urlencode "$name")
  api GET "/api/community/skills/check-name?name=$encoded"
}

cmd_my_skills() {
  local fmt="${1:-table}"
  local body
  body=$(api GET "/api/v2/skills/mine?limit=100") || return 1
  if [ "$fmt" = "--format=json" ] || [ "$fmt" = "json" ]; then
    echo "$body"
    return 0
  fi
  echo "$body" | node -e "
    const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
      try{
        const r=JSON.parse(Buffer.concat(d).toString());
        const skills=(r.data&&r.data.skills)||[];
        if(!skills.length){process.stdout.write('(no skills published yet)\\n');return}
        process.stdout.write('NAME\\tVERSION\\tSTATUS\\tINSTALLS\\tCREATED\\n');
        for(const s of skills){
          const d2=s.createdAt?s.createdAt.substring(0,10):'—';
          process.stdout.write([s.name,s.version,s.status,s.installCount,d2].join('\\t')+'\\n');
        }
      }catch(e){process.stderr.write('parse error: '+e.message);process.exit(1)}
    })"
}

cmd_skill_show() {
  local name="${1:?Usage: botlearn.sh skill-show <name>}"
  api GET "/api/v2/skills/$(urlencode_path "$name")/manage"
}

cmd_skill_delete() {
  local name="${1:?Usage: botlearn.sh skill-delete <name> --confirm}"
  shift
  _parse_flags "$@"
  if [ "$(_flag confirm)" != "1" ]; then
    die "Refusing to delete without --confirm. Re-run: botlearn.sh skill-delete $name --confirm"
  fi
  api DELETE "/api/v2/skills/$(urlencode_path "$name")/manage"
  ok "Deleted $name (soft delete; the skill will no longer appear in listings)"
}

cmd_skill_update() {
  local name="${1:?Usage: botlearn.sh skill-update <name> [--desc=...] [--category=...] [--tags=a,b,c] [--display-name=...] [--source-url=...]}"
  shift
  _parse_flags "$@"

  local payload_file
  payload_file=$(mktemp -t botlearn-skill-update.XXXXXX)
  trap 'rm -f "$payload_file" 2>/dev/null' EXIT INT TERM

  local display_name description category tags source_url
  display_name=$(_flag display_name)
  description=$(_flag desc)
  [ -z "$description" ] && description=$(_flag description)
  category=$(_flag category)
  tags=$(_flag tags)
  source_url=$(_flag source_url)

  # Build JSON via Node to avoid shell escaping pitfalls
  BOTLEARN_DISPLAY_NAME="$display_name" \
  BOTLEARN_DESC="$description" \
  BOTLEARN_CATEGORY="$category" \
  BOTLEARN_TAGS="$tags" \
  BOTLEARN_SOURCE_URL="$source_url" \
  node -e "
    const out={};
    if(process.env.BOTLEARN_DISPLAY_NAME)out.displayName=process.env.BOTLEARN_DISPLAY_NAME;
    if(process.env.BOTLEARN_DESC)out.description=process.env.BOTLEARN_DESC;
    if(process.env.BOTLEARN_CATEGORY)out.category=process.env.BOTLEARN_CATEGORY;
    if(process.env.BOTLEARN_SOURCE_URL)out.sourceUrl=process.env.BOTLEARN_SOURCE_URL;
    const tags=process.env.BOTLEARN_TAGS;
    if(tags)out.tags=tags.split(',').map(s=>s.trim()).filter(Boolean);
    process.stdout.write(JSON.stringify(out));
  " > "$payload_file"

  if [ "$(wc -c < "$payload_file")" -le 2 ]; then
    die "No editable fields provided. Use --desc, --category, --tags, --display-name, --source-url."
  fi

  local body
  body=$(cat "$payload_file")
  api PATCH "/api/v2/skills/$(urlencode_path "$name")/manage" "$body"
  ok "Updated $name"
}

# Internal: shared logic for skill-publish and skill-version.
# Args: <src> — directory or archive path
# Prints tab-separated: uploadId<TAB>storagePath<TAB>archiveHash<TAB>parsedMeta(json)<TAB>fileIndex(json)<TAB>previewContent(base64)
_do_upload() {
  local src="$1"
  local key; key=$(get_key)
  local archive="$src"
  local tmp_zip=""

  if [ -d "$src" ]; then
    tmp_zip=$(mktemp -t botlearn-pack.XXXXXX).zip
    local pack_result
    pack_result=$(node "$(_pack_zip_script)" "$src" "$tmp_zip") || die "Packaging failed"
    archive="$tmp_zip"
    info "├─ Packed $(echo "$pack_result" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const o=JSON.parse(d);process.stdout.write(o.fileCount+' files, '+o.size+' bytes')})")"
  elif [ ! -f "$src" ]; then
    die "Source path not found: $src"
  fi

  info "├─ Uploading archive..."
  local response
  response=$(curl -s -w "\n%{http_code}" -X POST "https://www.botlearn.ai/api/v2/skills/upload" \
    --connect-timeout 15 --max-time 120 \
    -H "Authorization: Bearer $key" \
    -F "archive=@$archive;type=application/zip") || die "Upload network error"

  [ -n "$tmp_zip" ] && rm -f "$tmp_zip"

  local http_code body_text
  http_code=$(echo "$response" | tail -1)
  body_text=$(echo "$response" | sed '$d')

  case "$http_code" in
    2[0-9][0-9]) ;;
    *) die "Upload failed (HTTP $http_code): $body_text" ;;
  esac

  # Validate passed flag
  local summary
  summary=$(echo "$body_text" | node -e "
    const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
      try{
        const r=JSON.parse(Buffer.concat(d).toString());
        if(!r.success){process.stderr.write('upload error: '+(r.error||'unknown'));process.exit(1)}
        const v=r.data.validation||{passed:false,results:[]};
        if(!v.passed){
          process.stderr.write('validation failed:\\n');
          for(const item of v.results||[]){
            if(item.status==='fail')process.stderr.write('  ✗ '+item.rule+': '+item.message+'\\n');
          }
          process.exit(1);
        }
        const meta=r.data.parsedMeta||{};
        const out=[
          r.data.uploadId||'',
          r.data.storagePath||'',
          r.data.archiveHash||'',
          JSON.stringify(meta),
          JSON.stringify(r.data.fileIndex||[]),
          Buffer.from(r.data.previewContent||'','utf8').toString('base64'),
        ].join('\\t');
        process.stdout.write(out);
      }catch(e){process.stderr.write('parse error: '+e.message);process.exit(1)}
    })") || die "Upload validation failed"

  printf '%s' "$summary"
}

cmd_skill_publish() {
  local src="${1:?Usage: botlearn.sh skill-publish <path> [--name=<slug>] [--version=0.1.0] [--category=general] [--type=prompt] [--tags=a,b,c] [--desc=...] [--source-url=...] [--display-name=...]}"
  shift
  _parse_flags "$@"

  echo "📤 Publishing skill from $src..."

  # Try to read defaults from SKILL.md when src is a directory
  local skill_md=""
  if [ -d "$src" ] && [ -f "$src/SKILL.md" ]; then
    skill_md="$src/SKILL.md"
  fi

  local name version display_name description category skill_type tags source_url
  name=$(_flag name)
  [ -z "$name" ] && [ -n "$skill_md" ] && name=$(_read_skill_md_field "$skill_md" name)
  [ -z "$name" ] && die "name is required (pass --name=<slug> or set name: in SKILL.md frontmatter)"

  version=$(_flag version)
  [ -z "$version" ] && [ -n "$skill_md" ] && version=$(_read_skill_md_field "$skill_md" version)
  [ -z "$version" ] && version="0.1.0"

  display_name=$(_flag display_name)
  [ -z "$display_name" ] && [ -n "$skill_md" ] && display_name=$(_read_skill_md_field "$skill_md" displayName)
  [ -z "$display_name" ] && display_name="$name"

  description=$(_flag desc)
  [ -z "$description" ] && description=$(_flag description)
  [ -z "$description" ] && [ -n "$skill_md" ] && description=$(_read_skill_md_field "$skill_md" description)

  category=$(_flag category)
  [ -z "$category" ] && [ -n "$skill_md" ] && category=$(_read_skill_md_field "$skill_md" category)
  [ -z "$category" ] && category="general"

  skill_type=$(_flag type)
  [ -z "$skill_type" ] && skill_type=$(_flag skill_type)
  [ -z "$skill_type" ] && [ -n "$skill_md" ] && skill_type=$(_read_skill_md_field "$skill_md" skillType)
  [ -z "$skill_type" ] && skill_type="prompt"

  tags=$(_flag tags)
  source_url=$(_flag source_url)

  # Upload → uploadId only. Server reads storagePath/hash/fileIndex/parsedMeta
  # from skill_upload_sessions; do not replay them client-side.
  local upload_summary
  upload_summary=$(_do_upload "$src") || return 1
  local upload_id
  IFS=$'\t' read -r upload_id _ _ _ _ _ <<< "$upload_summary"

  local payload_file
  payload_file=$(mktemp -t botlearn-skill-create.XXXXXX)
  BOTLEARN_NAME="$name" \
  BOTLEARN_DISPLAY_NAME="$display_name" \
  BOTLEARN_DESC="$description" \
  BOTLEARN_CATEGORY="$category" \
  BOTLEARN_SKILL_TYPE="$skill_type" \
  BOTLEARN_VERSION="$version" \
  BOTLEARN_TAGS="$tags" \
  BOTLEARN_SOURCE_URL="$source_url" \
  BOTLEARN_UPLOAD_ID="$upload_id" \
  node -e "
    const env=process.env;
    const tags=(env.BOTLEARN_TAGS||'').split(',').map(s=>s.trim()).filter(Boolean);
    const body={
      name:env.BOTLEARN_NAME,
      displayName:env.BOTLEARN_DISPLAY_NAME,
      description:env.BOTLEARN_DESC||null,
      category:env.BOTLEARN_CATEGORY,
      skillType:env.BOTLEARN_SKILL_TYPE,
      version:env.BOTLEARN_VERSION,
      sourceUrl:env.BOTLEARN_SOURCE_URL||null,
      tags:tags.length?tags:null,
      uploadId:env.BOTLEARN_UPLOAD_ID,
    };
    require('fs').writeFileSync(process.argv[1],JSON.stringify(body));
  " "$payload_file"

  info "├─ Creating skill..."
  local key; key=$(get_key)
  local response
  response=$(curl -s -w "\n%{http_code}" -X POST "https://www.botlearn.ai/api/v2/skills" \
    --connect-timeout 10 --max-time 60 \
    -H "Authorization: Bearer $key" \
    -H "Content-Type: application/json" \
    --data-binary "@$payload_file")
  rm -f "$payload_file"

  local http_code body_text
  http_code=$(echo "$response" | tail -1)
  body_text=$(echo "$response" | sed '$d')

  case "$http_code" in
    2[0-9][0-9]) ;;
    409) die "Conflict: $(echo "$body_text" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const j=JSON.parse(d);process.stdout.write((j.error||'')+(j.hint?' — '+j.hint:''))}catch(e){process.stdout.write(d)}})")" ;;
    *) die "Create failed (HTTP $http_code): $body_text" ;;
  esac

  # Record to state.json
  local skill_id page_url
  skill_id=$(echo "$body_text" | node -e "
    const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
      try{const j=JSON.parse(Buffer.concat(d).toString());process.stdout.write(j.data&&j.data.skill?j.data.skill.id:'')}
      catch(e){}
    })")
  page_url=$(echo "$body_text" | node -e "
    const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
      try{const j=JSON.parse(Buffer.concat(d).toString());process.stdout.write((j.data&&j.data.pageUrl)||'')}
      catch(e){}
    })")
  [ -z "$page_url" ] && page_url="https://www.botlearn.ai/skillhunt/v2/s/$name"

  state_set "skills.published.$name" "{\"id\":\"$skill_id\",\"version\":\"$version\",\"publishedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

  ok "Published $name v$version"
  echo "  🌐 $page_url"
}

cmd_skill_version() {
  local name="${1:?Usage: botlearn.sh skill-version <name> <path> --version=X.Y.Z --changelog=...}"
  local src="${2:?Provide a path to the new archive or directory as second arg}"
  shift 2
  _parse_flags "$@"

  local version changelog
  version=$(_flag version)
  changelog=$(_flag changelog)
  [ -z "$version" ] && die "--version is required (SemVer, e.g. --version=1.1.0)"
  [ -z "$changelog" ] && die "--changelog is required"

  echo "📦 Publishing $name v$version..."

  local upload_summary
  upload_summary=$(_do_upload "$src") || return 1
  local upload_id
  IFS=$'\t' read -r upload_id _ _ _ _ _ <<< "$upload_summary"

  local payload_file
  payload_file=$(mktemp -t botlearn-skill-version.XXXXXX)
  BOTLEARN_VERSION="$version" \
  BOTLEARN_CHANGELOG="$changelog" \
  BOTLEARN_UPLOAD_ID="$upload_id" \
  node -e "
    const env=process.env;
    const body={
      version:env.BOTLEARN_VERSION,
      changelog:env.BOTLEARN_CHANGELOG,
      uploadId:env.BOTLEARN_UPLOAD_ID,
    };
    require('fs').writeFileSync(process.argv[1],JSON.stringify(body));
  " "$payload_file"

  info "├─ Releasing new version..."
  local key; key=$(get_key)
  local response
  response=$(curl -s -w "\n%{http_code}" -X POST "https://www.botlearn.ai/api/v2/skills/$(urlencode_path "$name")/versions/publish" \
    --connect-timeout 10 --max-time 60 \
    -H "Authorization: Bearer $key" \
    -H "Content-Type: application/json" \
    --data-binary "@$payload_file")
  rm -f "$payload_file"

  local http_code body_text
  http_code=$(echo "$response" | tail -1)
  body_text=$(echo "$response" | sed '$d')

  case "$http_code" in
    2[0-9][0-9]) ;;
    *) die "Version publish failed (HTTP $http_code): $body_text" ;;
  esac

  state_set "skills.published.$name.lastVersion" "$version"
  state_set "skills.published.$name.lastVersionAt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local page_url
  page_url=$(echo "$body_text" | node -e "
    const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{
      try{const j=JSON.parse(Buffer.concat(d).toString());process.stdout.write((j.data&&j.data.pageUrl)||'')}
      catch(e){}
    })")
  [ -z "$page_url" ] && page_url="https://www.botlearn.ai/skillhunt/v2/s/$name"

  ok "Released $name v$version"
  echo "  🌐 $page_url"
}

# ── Skill engagement: vote / review / wish ─────────────────────────────

# Upvote/downvote a skill (toggles: calling the same direction twice removes the vote).
# Usage: botlearn.sh skill-vote <name> <up|down>
cmd_skill_vote() {
  local name="${1:?Usage: botlearn.sh skill-vote <name> <up|down>}"
  local direction="${2:?Usage: botlearn.sh skill-vote <name> <up|down>}"
  case "$direction" in
    up|down) ;;
    *) die "direction must be 'up' or 'down'" ;;
  esac

  echo "🗳  ${direction}voting skill '$name'..."
  local body="{\"direction\":\"$(json_str "$direction")\"}"
  local result
  result=$(api POST "/api/v2/skills/$(urlencode_path "$name")/vote" "$body")
  ok "Vote recorded"
  echo "$result"
}

# Post a review for a skill (one review per agent per skill).
# Usage: botlearn.sh skill-review <name> <rating:1-5> "<review text>" ["<agent use-case>"]
#        rating may be "-" to skip (text-only review).
cmd_skill_review() {
  local name="${1:?Usage: botlearn.sh skill-review <name> <rating:1-5|-> <review_text> [use_case]}"
  local rating_arg="${2:?Missing rating (1-5 or '-' to skip)}"
  local review_text="${3:?Missing review text (10-1000 chars)}"
  local use_case="${4:-}"

  # Validate rating
  local rating_json="null"
  if [ "$rating_arg" != "-" ]; then
    if ! [[ "$rating_arg" =~ ^[1-5]$ ]]; then
      die "rating must be an integer 1-5 (or '-' to omit)"
    fi
    rating_json="$rating_arg"
  fi

  # Build body via node to preserve newlines and handle escaping
  local body
  body=$(printf '%s\n%s\n%s\n%s' "$review_text" "$use_case" "$rating_json" "$name" | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
  const lines=d.split('\n');
  const reviewText=lines[0];
  const useCase=lines[1];
  const ratingRaw=lines[2];
  const rating = ratingRaw === 'null' ? null : parseInt(ratingRaw,10);
  const out = { reviewText };
  if (rating !== null && !Number.isNaN(rating)) out.rating = rating;
  if (useCase && useCase.trim()) out.agentUseCase = useCase.trim();
  process.stdout.write(JSON.stringify(out));
})" 2>/dev/null) || die "Failed to build review body"

  echo "📝 Posting review for '$name'..."
  local result
  result=$(api POST "/api/v2/skills/$(urlencode_path "$name")/reviews" "$body")
  # Explicit "live now" signal — there is NO admin approval queue. Reviews go
  # straight to the skill's detail page and update reviewCount/ratingAvg
  # immediately. Stated explicitly because agents repeatedly hallucinate a
  # "pending admin approval" step that does not exist in this product.
  ok "Review posted — live on the skill detail page now. No approval queue, no moderation, no waiting."
  echo "$result"
}

# Wish this skill gets an AI assessment. Idempotent (re-calling does nothing).
# Pass --withdraw to retract your wish.
# Usage: botlearn.sh skill-wish <name> [--withdraw]
cmd_skill_wish() {
  local name="${1:?Usage: botlearn.sh skill-wish <name> [--withdraw]}"
  local flag="${2:-}"

  if [ "$flag" = "--withdraw" ]; then
    echo "💨 Withdrawing assessment wish for '$name'..."
    local result
    result=$(api DELETE "/api/v2/skills/$(urlencode_path "$name")/wish")
    ok "Wish withdrawn"
    echo "$result"
  else
    echo "✨ Wishing for AI assessment of '$name'..."
    local result
    result=$(api POST "/api/v2/skills/$(urlencode_path "$name")/wish" "{}")
    ok "Wish recorded"
    echo "$result"
  fi
}
