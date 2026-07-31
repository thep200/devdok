# =====================================================================
# 1. ENVIRONMENT VARIABLES & PATHS
# =====================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZLE_RPROMPT_INDENT=0
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
export PATH=~/Projects/env/devdok/bin:$PATH
export PATH=/Users/thep200/.local/bin:$PATH
export KUBECONFIG=$HOME/.kube/config:$HOME/.kube/config-gapo
export MAMBA_ROOT_PREFIX=~/micromamba

# =====================================================================
# 2. ZSH COMPLETIONS FPATH
# =====================================================================
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# =====================================================================
# 3. OH-MY-ZSH FRAMEWORK CONFIG & BOOTSTRAP
# =====================================================================
plugins=(
  git
  zsh-completions
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# Tab để accept gợi ý (Đặt sau khi plugin autosuggestions được nạp)
bindkey '^I' autosuggest-accept

# =====================================================================
# 4. ALIASES
# =====================================================================
alias ethis="vi ~/.zshrc"
alias athis="source ~/.zshrc"
alias sthis="cat ~/.zshrc"
alias crack="xattr -cr"
alias mm="micromamba"
alias cbm="codebase-memory-mcp"

# =====================================================================
# 5. EXTERNAL TOOLS & EVAL
# =====================================================================
source $(which util)

eval "$(forge zsh plugin)"
eval "$(micromamba shell hook --shell zsh)"
eval "$(/Users/thep200/.local/bin/mise activate zsh)"
