status "Choose optional apps to be installed..."

OPTIONAL_APPS=("Brave" "Dropbox" "Signal" "Smartgit" "GitKraken" "Spotify" "Todoist")
DEFAULT_OPTIONAL_APPS='Dropbox,Signal,Smartgit,Spotify'

export SELECTED_OPTIONAL_APPS=$(gum choose "${OPTIONAL_APPS[@]}" --no-limit --selected $DEFAULT_OPTIONAL_APPS --height 10 --header "Select optional apps" | tr ' ' '-')
