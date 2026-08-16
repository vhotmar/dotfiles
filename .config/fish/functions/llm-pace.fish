function _llm_pace_reset_label --argument-names window_label reset_epoch
    set -l format
    if test $window_label = 5h
        set format '+%H:%M'
    else
        set format '+%b %e %H:%M'
    end

    set -l label (date -d "@$reset_epoch" $format 2>/dev/null)
    or set label (date -r $reset_epoch $format 2>/dev/null)
    string replace -a '  ' ' ' -- $label
end

function _llm_pace_format_line --argument-names provider window_label used_pct window_seconds reset_epoch now_epoch
    set -l seconds_left (math "$reset_epoch - $now_epoch")
    if test $seconds_left -le 0
        printf '%-7sstale | reset passed\n' $provider
        return 0
    end
    if test $seconds_left -gt $window_seconds
        set seconds_left $window_seconds
    end

    set -l time_left_pct (math --scale=6 "$seconds_left * 100 / $window_seconds")
    set -l elapsed_pct (math --scale=6 "100 - $time_left_pct")
    set -l pace_delta (math --scale=1 "$used_pct - $elapsed_pct")
    set -l quota_left (printf '%.0f' (math "100 - $used_pct"))
    set -l reset_label (_llm_pace_reset_label $window_label $reset_epoch)

    if test $pace_delta -eq 0
        printf '%-7s%s%% left | %s | on pace | resets %s\n' \
            $provider $quota_left $window_label $reset_label
    else if test $pace_delta -gt 0
        printf '%-7s%s%% left | %s | %.1fpp over pace · slow down | resets %s\n' \
            $provider $quota_left $window_label $pace_delta $reset_label
    else
        set -l under_delta (math --scale=1 "-$pace_delta")
        printf '%-7s%s%% left | %s | %.1fpp under pace · room to use more | resets %s\n' \
            $provider $quota_left $window_label $under_delta $reset_label
    end
end

function _llm_pace_newest_codex_limit --argument-names sessions_dir
    set -l candidates (
        for session_file in (find $sessions_dir -type f -name '*.jsonl' -print 2>/dev/null)
            set -l mtime (path mtime $session_file 2>/dev/null)
            test -n "$mtime"; and printf '%s\t%s\n' $mtime $session_file
        end | sort -rn
    )

    for candidate in $candidates
        set -l fields (string split -m 1 \t -- $candidate)
        set -l session_file $fields[2]
        set -l limit (jq -c \
            '.. | objects | select(has("rate_limits")) | .rate_limits | select(.limit_id == "codex" and .primary? != null)' \
            $session_file 2>/dev/null | tail -n 1)
        if test -n "$limit"
            echo $limit
            return 0
        end
    end
end

function _llm_pace_newest_claude_usage --argument-names cache_dir
    set -l newest_mtime -1
    set -l newest_usage

    for cache_file in (find $cache_dir -type f -name 'statusline-usage-cache-*.json' -print 2>/dev/null)
        jq -e '(.five_hour? != null) or (.seven_day? != null)' $cache_file >/dev/null 2>&1
        or continue

        set -l mtime (path mtime $cache_file 2>/dev/null)
        if test -n "$mtime"; and test $mtime -gt $newest_mtime
            set newest_mtime $mtime
            set newest_usage (jq -c '.' $cache_file 2>/dev/null)
        end
    end

    test -n "$newest_usage"; and echo $newest_usage
end

function _llm_pace_to_epoch --argument-names timestamp
    if string match -qr '^[0-9]+$' -- $timestamp
        echo $timestamp
        return 0
    end

    date -d $timestamp +%s 2>/dev/null
    or env TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%SZ' $timestamp +%s 2>/dev/null
end

function llm-pace --description 'Compare Codex and Claude quota usage with time elapsed'
    if not type -q jq
        echo 'llm-pace: jq is required' >&2
        return 1
    end

    set -l now_epoch (date +%s)
    set -q LLM_PACE_NOW; and set now_epoch $LLM_PACE_NOW

    set -l codex_root $HOME/.codex
    set -q CODEX_HOME; and set codex_root $CODEX_HOME
    set -l codex_sessions_dir $codex_root/sessions
    set -q LLM_PACE_CODEX_SESSIONS_DIR; and set codex_sessions_dir $LLM_PACE_CODEX_SESSIONS_DIR

    set -l codex_limit (_llm_pace_newest_codex_limit $codex_sessions_dir)
    if test -n "$codex_limit"
        set -l used_pct (echo $codex_limit | jq -r '.primary.used_percent // empty')
        set -l window_minutes (echo $codex_limit | jq -r '.primary.window_minutes // empty')
        set -l reset_epoch (echo $codex_limit | jq -r '.primary.resets_at // empty')
        if test -n "$used_pct"; and test -n "$window_minutes"; and test -n "$reset_epoch"
            set -l window_seconds (math "$window_minutes * 60")
            set -l window_label (math "$window_minutes / 1440")d
            _llm_pace_format_line Codex $window_label $used_pct $window_seconds $reset_epoch $now_epoch
        else
            echo 'Codex  unavailable'
        end
    else
        echo 'Codex  unavailable'
    end

    set -l claude_cache_dir /tmp/claude
    set -q LLM_PACE_CLAUDE_CACHE_DIR; and set claude_cache_dir $LLM_PACE_CLAUDE_CACHE_DIR
    set -l claude_usage (_llm_pace_newest_claude_usage $claude_cache_dir)
    if test -z "$claude_usage"
        echo 'Claude unavailable (start Claude Code once to refresh)'
        return 0
    end

    set -l printed_claude false
    for window_spec in five_hour:5h:18000 seven_day:7d:604800
        set -l parts (string split : $window_spec)
        set -l key $parts[1]
        set -l label $parts[2]
        set -l window_seconds $parts[3]
        set -l used_pct (echo $claude_usage | jq -r ".$key.utilization // empty")
        set -l reset_value (echo $claude_usage | jq -r ".$key.resets_at // empty")
        test -n "$used_pct"; and test -n "$reset_value"; or continue

        set -l reset_epoch (_llm_pace_to_epoch $reset_value)
        test -n "$reset_epoch"; or continue
        _llm_pace_format_line Claude $label $used_pct $window_seconds $reset_epoch $now_epoch
        set printed_claude true
    end

    if test $printed_claude = false
        echo 'Claude unavailable (start Claude Code once to refresh)'
    end
end
