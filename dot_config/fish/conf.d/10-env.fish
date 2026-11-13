# Environment — non-secret. Secrets live in conf.d/secrets.fish (gitignored).
set -g fish_greeting

# Bottom-pinned prompt toggle (config.fish + functions/clear.fish).
# 1 = pin prompt to the bottom of the terminal, 0 = default top prompt.
# Respects an inherited value, so `FISH_BOTTOM_PROMPT=0 fish` opts out.
set -q FISH_BOTTOM_PROMPT; or set -gx FISH_BOTTOM_PROMPT 0

# GPU (ROCm / HIP) — used by ML scripts, so set unconditionally.
set -gx HSA_OVERRIDE_GFX_VERSION 11.5.0
set -gx ROCR_VISIBLE_DEVICES 0
set -gx HIP_VISIBLE_DEVICES 0

# Thunderbolt eGPU (RTX 5060 Ti) is CUDA-only. niri and Umbriel start through
# a fish login shell, so this reaches the compositor and every app: EGL via
# Mesa, Vulkan via RADV. Otherwise glvnd loads libEGL_nvidia and the Vulkan
# loader the NVIDIA ICD in every process, and they open /dev/nvidiactl and
# hold the eGPU. Vulkan on the eGPU also crashes the machine: LM Studio's
# engine survey through the NVIDIA ICD (app, or the llmster daemon that `lms`
# starts) drops the card off the bus (Xid 79) and the platform resets (data
# fabric sync flood). CUDA uses neither loader. Gated on the Strix Halo iGPU.
if test -e /dev/dri/by-path/pci-0000:c4:00.0-render
    set -gx __EGL_VENDOR_LIBRARY_FILENAMES /usr/share/glvnd/egl_vendor.d/50_mesa.json
    set -gx VK_DRIVER_FILES /usr/share/vulkan/icd.d/radeon_icd.json
end

set -gx EGET_BIN $HOME/.local/bin

# Repo roots (ghq)
set -gx GHQ_ROOT $HOME/Code
set -gx CODE_ROOT $HOME/Code

set -gx EDITOR nvim
set -gx VISUAL nvim

# Go env (GOPATH/GOBIN) is pinned in ~/.config/mise/config.toml [env] because
# mise's fish hook re-applies env each prompt and would clobber a shell-set
# GOBIN. GOROOT is provided by mise (toolchain under ~/.local/share/mise).

# Android SDK — relocated under ~/.local/share/android.
set -gx ANDROID_HOME $HOME/.local/share/android
set -gx ANDROID_SDK_ROOT $ANDROID_HOME

# Git hosts (non-secret; tokens are in secrets.fish)
set -gx GITEA_LOGIN prad.codes
set -gx GITLAB_HOST git.sonr.org

# GITHUB_TOKEN from gh's keyring login — never stored on disk. An inherited
# value wins, so nested shells skip the gh call.
if not set -q GITHUB_TOKEN; and command -q gh
    set -l _gh_token (gh auth token 2>/dev/null)
    test -n "$_gh_token"; and set -gx GITHUB_TOKEN $_gh_token
end

# free-router (localhost freellmapi): FREE_ROUTER_PORT, FREE_ROUTER_API_KEY.
# KEY=VALUE file shared with free-router.service and bash/zsh; only present on
# desktop/laptop roles of the chezmoi repo.
if test -r ~/.config/free-router/env
    for _line in (string match -rv '^\s*(#|$)' < ~/.config/free-router/env)
        set -gx (string split -m1 = -- $_line)
    end
    set -e _line
end

set -gx EDITOR nvim
set -gx VISUAL nvim

test -x /usr/bin/brave-origin; and set -gx BROWSER /usr/bin/brave-origin
test -x /usr/bin/chromium; and set -gx CHROME_EXECUTABLE /usr/bin/chromium
# Puppeteer / CDP tools — chrome-headless-shell via @puppeteer/browsers,
# symlinked from ~/.config/chrome-headless-shell/<version>/ into ~/.local/bin.
# NOTE: omp's browser tool prefers detected system Chrome over this env var;
# ~/.local/bin/google-chrome-stable shims its first detection candidate to the
# same binary (and masks the broken /usr/bin/google-chrome wrapper).
set -gx PUPPETEER_EXECUTABLE_PATH $HOME/.local/bin/chrome-headless-shell
set -gx ZEAL_DOCSETS $HOME/.var/app/org.zealdocs.Zeal/data/Zeal/Zeal/docsets
set -gx SHARP_IGNORE_GLOBAL_LIBVIPS 1

set -gx FZF_DEFAULT_OPTS "
  --height=~40%
  --layout=default
  --info=inline-right
  --border=rounded
  --prompt='  '
  --pointer='▶'
  --marker='✓'
  --color=fg:#ffffff,fg+:#ffffff,bg:-1,bg+:#3c4048
  --color=hl:#5ef1ff,hl+:#5ef1ff
  --color=info:#7b8496,header:#7b8496,border:#7b8496
  --color=prompt:#5ef1ff,pointer:#ffaecf,marker:#5eff6c,spinner:#f1ff5e
  --color=gutter:-1,query:#ffffff
"
