

# Download zimfw
if [[ ${DRY_RUN} == 0 ]] ; then
  wget -qO - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
else
  echo "wget -qO - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh"
fi

# Dotfiles
${CMD} git clone https://github.com/tommoyer/dotfiles.git ~/.dotfiles
pushd ~/.dotfiles
${CMD} git remote set-url origin git@github.com:tommoyer/dotfiles.git
${CMD} stow apps
${CMD} stow chrome
${CMD} stow gpg
${CMD} stow latex
${CMD} stow misc
${CMD} stow pics
${CMD} stow ssh
${CMD} stow tmux
${CMD} stow vcs
${CMD} rm ~/.zshrc ~/.zimrc
${CMD} stow zsh
${CMD} stow subl
${CMD} stow watson
popd # ~/.dotfiles

${CMD} chmod go-rwx ~/.gnupg ~/.ssh

${CMD} xdg-settings set default-web-browser re.sonny.Junction.desktop

${CMD} update-desktop-database ~/.local/share/applications
${CMD} update-desktop-database ~/.local/share/flatpak/exports/share/applications

if [[ ${DRY_RUN} == 0 ]] ; then
  echo "emulate sh -c 'source /etc/profile'" | sudo tee -a /etc/zsh/zprofile
else
  echo "echo \"emulate sh -c 'source /etc/profile'\" | sudo tee -a /etc/zsh/zprofile"
fi

${CMD} gpg --keyserver keyserver.ubuntu.com --search-keys tom.moyer@canonical.com

${CMD} apt-file update

# Install tailscale and bring up
if [[ ${DRY_RUN} == 0 ]] ; then
  wget -qO - https://tailscale.com/install.sh | sh
else
  echo "wget -qO - https://tailscale.com/install.sh | sh"
fi
${CMD} sudo tailscale up

echo "Run the below snippet for setting up YubiKeys"
cat <<'EOF'
pamu2fcfg | tee u2f_mappings               # Main YubiKey
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey
echo >> u2f_mappings
sudo mv u2f_mappings /etc

sudo -i

cd /etc/pam.d

echo 'auth sufficient pam_u2f.so authfile=/etc/u2f_mappings cue' > common-u2f

for f in $(grep -l "@include common-auth" *); do
  if [[ $f == *~ ]]; then continue; fi
  if grep -q "@include common-u2f" $f; then continue; fi
  mv $f $f~
  awk '/@include common-auth/ {print "@include common-u2f"}; {print}' $f~ > $f
done

exit
EOF

echo "To rebuild GPG keyring: gpg-connect-agent \"scd serialno\" \"learn --force\" /bye"
echo ""
echo "Check the following for a Tailscale tray icon"
echo "https://github.com/mattn/tailscale-systray"
echo ""
echo "Bootstrap complete, please check output carefully"
