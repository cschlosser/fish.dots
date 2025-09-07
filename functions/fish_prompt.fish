function cstar_segment_divide_left
  set -l from_var "cstar_$argv[1]"
  set -l from_name "$from_var""_bg"
  set -l from $$from_name
  set -l to_var "cstar_$argv[2]"
  set -l to_name "$to_var""_bg"
  set -l to $$to_name

  if test -z "$$from_var"
    return
  end
  if test -z "$$to_var"
    set -f to normal
  end
  echo (set_color -b $to $from)\uE0B0(set_color normal)
end

function fish_prompt --description "The left side of the C-Star prompt"
  echo -e "$cstar_user$cstar_host$(cstar_segment_divide_left user pwd)$cstar_pwd$(cstar_segment_divide_left pwd git)$cstar_git$(cstar_segment_divide_left git normal)\n$cstar_user_marker$(cstar_segment_divide_left user_marker normal) "
end