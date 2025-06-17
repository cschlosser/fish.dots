function gglog --wraps='git log --graph --pretty --all' --description 'alias gglog git log --graph --pretty --all'
  git log --graph --pretty --all $argv
        
end
