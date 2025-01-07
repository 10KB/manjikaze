install_if_not_present "kubectl" "yay -S kubectl --noconfirm --noprogressbar --quiet"
install_if_not_present "helm" "yay -S helm --noconfirm --noprogressbar --quiet"
install_if_not_present "eksctl" "yay -S eksctl --noconfirm --noprogressbar --quiet"