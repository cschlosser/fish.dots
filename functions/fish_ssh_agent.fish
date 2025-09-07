function fish_ssh_agent --wraps='eval (ssh-agent -c)' --description 'alias fish_ssh_agent eval (ssh-agent -c)'
  eval (ssh-agent -c) $argv
        
end
