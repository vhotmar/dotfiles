#!/usr/bin/env nu

# fill -w

def print-table [] {
  let table = $in

  let column_names = $table | columns
  let column_count = $table | columns | length

  let column_sizes = $column_names |
    each {|column| 
      $table | get $column | each { into string | str length } | math max 
    } |
    zip $column_names


  $column_sizes | enumerate | print

  # Print headers
  $column_sizes |
    each { |col| $col.1 | fill -w $col.0 } |
    str join |
    print

  # Print columns
  $table |
    each {|row|
      ($column_sizes |
        enumerate |
        each {|it|
          let data = $row | get $it.1.1 
          let width = $it.1.0

          if $it.0 == $column_count {
            $data | fill -w $width
          } else {
            $data
          }
        } |
        str join)
    } |
    str join (char nl)
}

def make-table [headers: list<string>] {
  # print ($in | describe)
  let rows = $in | prepend $headers | debug | each { into record } | headers
  let row_length = $rows | columns | length
  
  $rows | values | each { each { into string | str length } | math max }
}

def process-list [] {
  ps -l |
  select pid name command |
  each {|it| [$it.pid $it.name $it.command] | str join (char tab) } |
  str join (char newline)
}

export def "main list" [] {
  (process-list)
}

export def main [] {
  (fzf
    --tmux 55%,80%
    --ansi
    --bind "start:reload:kill-process.nu list")
}

#   --bind $"start:reload:($rg_prefix) {q}"
#   --bind $"change:reload:sleep 0.1; ($rg_prefix) {q} || true")
#
#
# let ps_command = "ps"
# let ps_opts = [-A "-opid,command"]
# let ps_whole = [ps_command ...ps_opts] | str join
#
# run-external $ps_command ...$ps_opts
#
# let pid = (
#   run-external $ps_command ...$ps_opts |
#   (fzf 
#     --prompt "Processes>"
#     --tmux 55%,80%
#     --ansi
#     --with-shell=nu
#     --header-lines 1
#     --border-label rounded
#     --header '  ^d kill process  ^r reload'
#     --preview "ps -o 'pid,ppid=PARENT,user,%cpu,rss=RSS_IN_KB,start=START_TIME,command' -p {1} || echo 'Cannot preview {1} because it exited.'"
#     --preview-window "bottom:4:wrap"
#     --bind $"ctrl-d:execute\(kill -9 {1})+reload\(($ps_whole))"
#     --bind $"ctrl-r:reload\(($ps_whole))"
#     --bind 'enter:become(kill -9 {1})'))
