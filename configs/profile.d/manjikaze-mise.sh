# Installed by Manjikaze. A desktop session and the services in it start from a login shell, not
# from .zshrc where mise is activated, so they find the tools installed with mise through its
# shims. The shims come last: outside a shell with mise active, a program in /usr/bin keeps
# precedence, such as the system Python with the GNOME bindings that mise's Python lacks.
manjikaze_mise_shims="${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims"
case ":$PATH:" in
    *":$manjikaze_mise_shims:"*) ;;
    *) PATH="$PATH:$manjikaze_mise_shims" ;;
esac
export PATH
unset manjikaze_mise_shims
