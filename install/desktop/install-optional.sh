if [[ -v SELECTED_OPTIONAL_APPS ]]; then
	apps=$SELECTED_OPTIONAL_APPS

	if [[ -n "$apps" ]]; then
		for app in $apps; do
			source "./install/desktop/optional/app-${app,,}.sh"
		done
	fi
fi
