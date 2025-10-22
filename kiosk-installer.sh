#!/bin/bash

# THE KIOSK URL
KIOSK_URL="https://example.com/"


RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color


if [ "$EUID" -ne 0 ]
        then echo -e "${RED}Please run as root${NC}"
        exit
fi


# get software
echo -e "${GREEN}Installing required packages via apt...${NC}"
cmdout=$(apt-get update && apt-get install \
                unclutter \
                xorg \
                firefox-esr \
                openbox \
                lightdm \
                locales \
                zenity \
                psmisc \
                -y 2>&1)
es=$?
if ((es)); then
        echo -e >&2 "${RED}Error installing packages ($es):${NC}\n${ORANGE}$cmdout${NC}"
        echo -e "${RED}ABORTING KIOSK INSTALL!${NC}"
        exit 1
else
        echo -e "${GREEN}Install of packages successful.${NC}"
fi


echo -e "${GREEN}Creating users and groups...${NC}"

# dir
mkdir -p /home/kiosk/.config/openbox

# create group
getent group kiosk &>/dev/null || groupadd kiosk

# create user if not exists
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash

# rights
chown -R kiosk:kiosk /home/kiosk


echo -e "${GREEN}Writing configs...${NC}"

# remove virtual consoles
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# create config
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
#xserver-command=X -nocursor -nolisten tcp
xserver-command=X -s 0 dpms
autologin-user=kiosk
autologin-session=openbox
EOF

# create firefox policies
mkdir -p /etc/firefox
mkdir -p /etc/firefox/policies
if [ -e "/etc/firefox/policies/policies.json" ]; then
  mv /etc/firefox/policies/policies.json /etc/firefox/policies/policies.json.backup
fi

INTERNAL_BASE_URL="$(echo $KIOSK_URL | cut -d'/' -f1,2,3)"

cat > /etc/firefox/policies/policies.json << EOF
{
        "policies": {
                "AllowFileSelectionDialogs": false,
                "AppAutoUpdate": false,
                "AutofillAddressEnabled": false,
                "AutofillCreditCardEnabled": false,
                "BlockAboutAddons": true,
                "BlockAboutConfig": true,
                "BlockAboutProfiles": true,
                "BlockAboutSupport": true,
                "DisableAppUpdate": true,
                "DisableDeveloperTools": true,
                "DisableFeedbackCommands": true,
                "DisableFirefoxAccounts": true,
                "DisableFirefoxScreenshots": true,
                "DisableFirefoxStudies": true,
                "DisableFormHistory": true,
                "DisableMasterPasswordCreation": true,
                "DisablePasswordReveal": true,
                "DisablePocket": true,
                "DisableProfileImport": true,
                "DisableProfileRefresh": true,
                "DisableSafeMode": true,
                "DisableSetDesktopBackground": true,
                "DisableSystemAddonUpdate": true,
                "DisableTelemetry": true,
                "DisableThirdPartyModuleBlocking": true,
                "DisplayBookmarksToolbar": true,
                "DisplayMenuBar": false,
                "DontCheckDefaultBrowser": true,
                "EnableTrackingProtection": {
                        "Value": true,
                        "Locked": true
                },
                "FirefoxSuggest": {
                        "WebSuggestions": false,
                        "SponsoredSuggestions": false,
                        "ImproveSuggest": false,
                        "Locked": true
                },
                "GenerativeAI": {
                        "Chatbot": false,
                        "LinkPreviews": false,
                        "TabGroups": false,
                        "Locked": true
                },
                "Homepage": {
                        "URL": "$KIOSK_URL",
                        "Locked": true,
                        "StartPage": "homepage-locked"
                },
                "ManualAppUpdateOnly": true,
                "NewTabPage": false,
                "NoDefaultBookmarks": true,
                "OfferToSaveLogins": false,
                "PasswordManagerEnabled": false,
                "PictureInPicture": {
                        "Enabled": false,
                        "Locked": true
                },
                "PopupBlocking": {
                        "Default": true,
                        "Locked": true
                },
                "PrintingEnabled": false,
                "PromptForDownloadLocation": false,
                "SanitizeOnShutdown": true,
                "SearchBar": "separate",
                "SearchSuggestEnabled": false,
                "ShowHomeButton": false,
                "SkipTermsOfUse": true,
                "TranslateEnabled": false,
                "UserMessaging": {
                        "ExtensionRecommendations": false,
                        "FeatureRecommendations": false,
                        "UrlbarInterventions": false,
                        "SkipOnboarding": true,
                        "MoreFromMozilla": false,
                        "FirefoxLabs": false,
                        "Locked": true
                },
                "Permissions": {
                        "Autoplay": {
                                "Allow": ["$INTERNAL_BASE_URL"],
                                "BlockNewRequests": true,
                                "Locked": true
                        }
                }
        }
}
EOF

# create autostart
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

unclutter -idle 0 -jitter 2000 &

# Wait for Network
zenity --title="Connecting..." --ok-label="" --width=500 --height=100 --info --no-wrap --no-markup --text="System is waiting for an internet connection" &
while ! ping -c 1 -W 1 8.8.8.8; do
        echo "Waiting for internet connection...."
        sleep 1
done
killall zenity &

# Start Kiosk
while :
do
  xrandr --auto
#  firefox-esr --kiosk --private-window --disable-pinch $KIOSK_URL    # The "--private-window" option disables the autoplay permission, but the policies disable any saving of personal data and autofill functionality anyway so this can be skipped (still, be careful)
  firefox-esr --kiosk --disable-pinch $KIOSK_URL
  sleep 5
done &
EOF


echo -e "${GREEN}Done!${NC}"
echo -e "${ORANGE}Rebooting in 30s, press ctrl+c to abort reboot${NC}"

sleep 30

reboot now
