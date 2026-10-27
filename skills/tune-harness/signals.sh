#!/usr/bin/env bash
# Usage: signals.sh <transcript.jsonl>...
# Prints one TSV row per failure signal so a transcript never has to be read whole:
#   session  time  kind  before  text
# kind: human | interrupt | command | error | denied | skill
# before: the agent's last few actions before a human/interrupt row (tool:arg | text).
set -euo pipefail

for f in "$@"; do
  jq -rs --arg sid "$(basename "$f" .jsonl)" '
    def clip(n): tostring | gsub("\\s+"; " ") | .[:n];
    def body: if . == null then "" elif type == "string" then .
              else map(if .type == "text" then .text
                       elif .type == "tool_result" then (.content // "" | if type == "string" then . else map(.text? // "") | join(" ") end)
                       else "" end) | join(" ") end;
    def human: .type == "user" and .isMeta != true
               and (.origin.kind == "human"
                    or (.origin == null and (.message.content | type) == "string"
                        and (.message.content | startswith("<") | not)));
    def row($kind; $before; $text): [$sid, (.timestamp // "" | .[:19]), $kind, ($before | clip(240)), ($text | clip(400))] | @tsv;

    foreach .[] as $r ({recent: [], out: []};
      .out = [] |
      if $r.type == "assistant" then
        reduce ($r.message.content // [])[] as $c (.;
          if $c.type == "tool_use" then
            .recent = (.recent + [$c.name + ":" + (($c.input.command // $c.input.file_path // $c.input.skill // $c.input.description // "") | clip(70))])[-4:]
            | if $c.name == "Skill" then .out += [$r | row("skill"; ""; $c.input.skill)] else . end
          elif $c.type == "text" and ($c.text | length) > 0 then
            .recent = (.recent + [$c.text | clip(90)])[-4:]
          else . end)
      elif $r.type == "user" then
        ($r.message.content | body | gsub("(?s)<system-reminder>.*?</system-reminder>\\s*"; "")) as $t
        | (.recent | join(" | ")) as $b
        | if ($t | startswith("[Request interrupted")) then .out = [$r | row("interrupt"; $b; $t)]
          elif ($r | human) then
            (if ($t | test("^\\s*<command-")) then "command" else "human" end) as $k
            | .out = [$r | row($k; $b; $t)]
          elif ($r.message.content | type) == "array" then
            .out = [$r.message.content[] | select(.type == "tool_result" and .is_error == true)
                    | ([.] | body) as $e
                    | $r | row((if ($e | test("denied|doesn.t want to proceed|rejected"; "i")) then "denied" else "error" end); ""; $e)]
          else . end
      else . end;
      .out[])
  ' "$f"
done
