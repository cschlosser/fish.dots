status is-interactive || exit

set -q cstar_date_format || set -g cstar_date_format "%Y-%m-%dT%H:%M:%S%z"
set -q cstar_default_bg || set -g cstar_default_bg 333333
set -q cstar_default_fg || set -g cstar_default_fg a9b7c6
set -q cstar_user_bg || set -g cstar_user_bg $cstar_default_fg
set -q cstar_user_fg || set -g cstar_user_fg $cstar_default_bg
set -q cstar_pwd_bg || set -g cstar_pwd_bg $cstar_default_bg
set -q cstar_pwd_fg || set -g cstar_pwd_fg $cstar_default_fg
set -q cstar_git_bg || set -g cstar_git_bg $cstar_default_fg
set -q cstar_git_fg || set -g cstar_git_fg $cstar_default_bg
set -q cstar_user_marker_default_bg || set -g cstar_user_marker_default_bg $cstar_default_bg
set -q cstar_user_marker_fg || set -g cstar_user_marker_fg $cstar_default_fg
set -q cstar_exit_status_bg || set -g cstar_exit_status_bg red
set -q cstar_exit_status_fg || set -g cstar_exit_status_fg white
set -q cstar_datetime_bg || set -g cstar_datetime_bg $cstar_default_bg
set -q cstar_datetime_fg || set -g cstar_datetime_fg $cstar_default_fg
set -q cstar_command_time_bg || set -g cstar_command_time_bg $cstar_default_fg
set -q cstar_command_time_fg || set -g cstar_command_time_fg $cstar_default_bg

set -g _cstar_git_async _cstar_git_async_$fish_pid
set -g _cstar_git_cached_pwd _cstar_git_cached_pwd_$fish_pid

function cstar_colorize
  set -l bg $argv[3]
  set -l fg $argv[4]
  set -g "$argv[1]" "$(set_color -b $bg $fg) $argv[2] $(set_color normal)"
end

function cstar_command_time --on-event fish_postexec
  set -l dur $CMD_DURATION
  set -l time_str ""

  if test $dur -lt 1000
    set time_str (printf "%dms" $dur)
  else
    set -l s (math "floor($dur / 1000)")
    set -l ms_rem (math "$dur % 1000")

    if test $s -lt 60
      set time_str (printf "%d.%03ds" $s $ms_rem)
    else
      set -l m (math "floor($s / 60)")
      set -l s_rem (math "$s % 60")

      if test $m -lt 60
        set time_str (printf "%d:%02d.%03d" $m $s_rem $ms_rem)
      else
        # If the program was running for more than an hour it's probably ok to
        # calculate the totals eagerly to improve readability a bit.
        set -l h (math "floor($m / 60)")
        set -l m_rem (math "$m % 60")
        set -l d (math "floor($h / 24)")
        set -l w (math "floor($d / 7)")
        set -l mo (math "floor($d / 30)")
        set -l y (math "floor($d / 365)")

        if test $h -lt 24
          set time_str (printf "%d:%02d:%02d" $h $m_rem $s_rem)
        else if test $d -lt 7
          set -l h_rem (math "$h % 24")
          set time_str (printf "%dd %dh" $d $h_rem)
        else if test $w -lt 4
          set -l d_rem (math "$d % 7")
          set time_str (printf "%dw %dd" $w $d_rem)
        else if test $mo -lt 12
          set -l w_rem (math "floor(($d % 30) / 7)")
          set time_str (printf "%dmo %dw" $mo $w_rem)
        else
          set -l mo_rem (math "floor(($d % 365) / 30)")
          set time_str (printf "%dy %dmo" $y $mo_rem)
        end
      end
    end
  end

  if test -z "$time_str"
    set time_str "0ms"
  end

  cstar_colorize cstar_command_time $time_str $cstar_command_time_bg $cstar_command_time_fg
end

function cstar_datetime --on-event fish_prompt
  cstar_colorize cstar_datetime (date "+$cstar_date_format") $cstar_datetime_bg $cstar_datetime_fg
end

function cstar_exit_status --on-event fish_postexec
  set cmd_status $status
  if test $cmd_status -eq 0
    set -ge cstar_exit_status
  else
    cstar_colorize cstar_exit_status (set_color -o)\uf00d $cstar_exit_status_bg $cstar_exit_status_fg
  end
end

function cstar_git_query_async --on-event fish_prompt
  if ! command -q git
    return
  end
  set -l cwd_is_repo "$(git rev-parse --is-inside-work-tree 2> /dev/null)"
  if test "$cwd_is_repo" != "true"
    set -Ue $_cstar_git_async
    set -Ue $_cstar_git_cached_pwd
  end

  set -l cached_pwd $$_cstar_git_cached_pwd

  if test "$PWD" != "$cached_pwd"
    if test -n "$cwd_is_repo"
      set -U $_cstar_git_async \ue727
    else
      set -Ue $_cstar_git_async
    end
  end

  fish --private --command "set -x __fish_git_prompt_show_informative_status 1 && \
      set -U $_cstar_git_async (fish_git_prompt '%s') && \
      set -q $_cstar_git_async || set -Ue $_cstar_git_async $git_status && \
      set -U $_cstar_git_cached_pwd \"$PWD\"
  "&
end

function cstar_git --on-variable $_cstar_git_async
  set git_status $$_cstar_git_async
  if test -n "$git_status"
    cstar_colorize cstar_git $git_status $cstar_git_bg $cstar_git_fg
  else
    set -ge cstar_git
  end
  commandline --function repaint
end

function cstar_user --on-variable __fish_initialized
  set -l user_string (whoami)
  if test -n "$SSH_CONNECTION"
    set -f user_string "$user_string@$(prompt_hostname)"
  end
  cstar_colorize cstar_user "$user_string" $cstar_user_bg $cstar_user_fg
end

function cstar_user_marker --on-variable __fish_initialized
  switch (whoami)
    case "root"
      set -g cstar_user_marker_bg red
      set -f char "#"
    case '*'
      set -g cstar_user_marker_bg $cstar_user_marker_default_bg
      set -f char "\$"
  end
  cstar_colorize cstar_user_marker $char $cstar_user_marker_bg $cstar_user_marker_fg
end

function cstar_pwd --on-variable PWD --on-variable __fish_initialized
  cstar_colorize cstar_pwd (prompt_pwd) $cstar_pwd_bg $cstar_pwd_fg
end

function cstar_cleanup --on-event fish_exit
    set -Ue $_cstar_git_async
    set -Ue $_cstar_git_cached_pwd
end
