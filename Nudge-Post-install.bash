#!/bin/bash

####################################################################################################
#
#    Nudge Post-install
#
#    Purpose: Configures Nudge to company standards post-install
#    https://github.com/macadmins/nudge/blob/main/README.md#configuration
#
####################################################################################################
#
#   Version 0.0.15, 08-Jun-2022, Dan K. Snelson (@dan-snelson)
#       Added an `Uninstall` option to the `resetConfiguration` function
#       Removed verbosity when removing files
#       Started macOS Ventura logic (using macOS Monterey's deadline)
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="0.0.15"
scriptResult=""
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )
authorizationKey="${4}"                     # Authorization Key to prevent unauthorized execution via Jamf Remote
plistDomain="${5}"                          # Reverse Domain Name Notation (i.e., "org.churchofjesuschrist")
resetConfiguration="${6}"                   # Configuration Files to Reset (i.e., None (blank) | All | JSON | LaunchAgent | LaunchDaemon)
requiredBigSurMinimumOSVersion="${7}"       # Required macOS Big Sur Minimum Version (i.e., 11.6.5)
requiredBigSurInstallationDate="${8}"       # Required macOS Big SurInstallation Date & Time (i.e., 2022-03-21T10:00:00Z)
requiredMontereyMinimumOSVersion="${9}"     # Required macOS Monterey Minimum Version (i.e., 12.3)
requiredMontereyInstallationDate="${10}"    # Required macOS Monterey Installation Date & Time (i.e., 2022-03-21T10:00:00Z)
requiredVenturaMinimumOSVersion="${11}"     # Required macOS Ventura Minimum Version (i.e., 13.1)
jsonPath="/Library/Preferences/${plistDomain}.Nudge.json"
launchAgentPath="/Library/LaunchAgents/${plistDomain}.Nudge.plist"
launchDaemonPath="/Library/LaunchDaemons/${plistDomain}.Nudge.logger.plist"

# Set deadline variable based on OS version
osProductVersion=$( /usr/bin/sw_vers -productVersion )
case "${osProductVersion}" in
    11* ) deadline="${requiredBigSurInstallationDate}"    ;;
    12* ) deadline="${requiredMontereyInstallationDate}"  ;;
    13* ) deadline="${requiredMontereyInstallationDate}"  ;;
esac



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for a specified value in Parameter 4 to prevent unauthorized script execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function authorizationCheck() {

    if [[ "${authorizationKey}" != "PurpleMonkeyDishwasher" ]]; then

        scriptResult+="Error: Incorrect Authorization Key; exiting."
        echo "${scriptResult}"
        exit 1

    else

        scriptResult+="Correct Authorization Key, proceeding; "

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function resetConfiguration() {

    scriptResult+="Reset Configuration: ${1}; "

    case ${1} in

        "All" )
            # Reset JSON, LaunchAgent, LaunchDaemon, Hide Nudge
            scriptResult+="Reset All Configuration Files … "

            # Reset User Preferences
            # For testing only; see:
            # * https://github.com/macadmins/nudge/wiki/User-Deferrals#resetting-values-when-a-new-nudge-event-is-detected
            # * https://github.com/macadmins/nudge/wiki/User-Deferrals#testing-and-resetting-nudge

            # echo "Reset User Preferences"
            # /bin/rm -f /Users/"${loggedInUser}"/Library/Preferences/com.github.macadmins.Nudge.plist
            # /usr/bin/pkill -l -U "${loggedInUser}" cfprefsd
            # scriptResult+="Removed User Preferences; "

            # Reset JSON
            scriptResult+="Remove ${jsonPath} … "
            /bin/rm -f "${jsonPath}" 2>&1
            scriptResult+="Removed ${jsonPath}; "

            # Reset LaunchAgent
            scriptResult+="Unload ${launchAgentPath} … "
            /bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}" 2>&1
            scriptResult+="Remove ${launchAgentPath} … "
            /bin/rm -f "${launchAgentPath}"  2>&1
            scriptResult+="Removed ${launchAgentPath}; "

            # Reset LaunchDaemon
            scriptResult+="Unload ${launchDaemonPath} … "
            /bin/launchctl unload -w "${launchDaemonPath}" 2>&1
            scriptResult+="Remove ${launchDaemonPath} … "
            /bin/rm -f "${launchDaemonPath}" 2>&1
            scriptResult+="Removed ${launchDaemonPath}; "

            # Hide Nudge in Finder
            scriptResult+="Hide Nudge in Finder … "
            /usr/bin/chflags hidden "/Applications/Utilities/Nudge.app" 
            scriptResult+="Hid Nudge in Finder; "

            # Hide Nudge in Launchpad
            scriptResult+="Hide Nudge in Launchpad … "
            if [[ -z "$loggedInUser" ]]; then
                scriptResult+="Did not detect logged-in user"
            else
                /usr/bin/sqlite3 $(/usr/bin/sudo find /private/var/folders \( -name com.apple.dock.launchpad -a -user "${loggedInUser}" \) 2> /dev/null)/db/db "DELETE FROM apps WHERE title='Nudge';"
                /usr/bin/killall Dock
                scriptResult+="Hid Nudge in Launchpad for ${loggedInUser}; "
            fi

            scriptResult+="Reset All Configuration Files; "
            ;;

        "Uninstall" )
           # Uninstall Nudge Post-install
            scriptResult+="Uninstalling Nudge Post-install … "

            # Uninstall JSON
            /bin/rm -f "${jsonPath}"
            scriptResult+="Uninstalled ${jsonPath}; "

            # Uninstall LaunchAgent
            scriptResult+="Unload ${launchAgentPath} … "
            /bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
            /bin/rm -f "${launchAgentPath}"
            scriptResult+="Uninstalled ${launchAgentPath}; "

            # Uninstall LaunchDaemon
            scriptResult+="Unload ${launchDaemonPath} … "
            /bin/launchctl unload -w "${launchDaemonPath}"
            /bin/rm -f "${launchDaemonPath}"
            scriptResult+="Uninstalled ${launchDaemonPath}; "

            # Exit
            scriptResult+="Uninstalled all Nudge Post-install configuration files; "
            scriptResult+="Thanks for using Nudge Post-install!"
            echo "${scriptResult}"
            exit 0
            ;;

        "JSON" )
            # Reset JSON
            scriptResult+="Remove ${jsonPath} … "
            /bin/rm -f "${jsonPath}"
            scriptResult+="Removed ${jsonPath}; "
            ;;

        "LaunchAgent" )
            # Reset LaunchAgent
            scriptResult+="Unload ${launchAgentPath} … "
            /bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
            scriptResult+="Remove ${launchAgentPath} … "
            /bin/rm -f "${launchAgentPath}"
            scriptResult+="Removed ${launchAgentPath}; "
            ;;

        "LaunchDaemon" )
            # Reset LaunchDaemon
            scriptResult+="Unload ${launchDaemonPath} … "
            /bin/launchctl unload -w "${launchDaemonPath}"
            scriptResult+="Remove ${launchDaemonPath} … "
            /bin/rm -f "${launchDaemonPath}"
            scriptResult+="Removed ${launchDaemonPath}; "
            ;;

        * )
            # None of the expected options was entered; don't reset anything
            scriptResult+="None of the expected reset options was entered; don't reset anything; "
            ;;

    esac

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Nudge Post-install (${scriptVersion}) "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Authorization
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

authorizationCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resetConfiguration "${resetConfiguration}"




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge Logger LaunchDaemon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${launchDaemonPath} ]]; then

    scriptResult+="Create ${launchDaemonPath} … "

    cat <<EOF > "${launchDaemonPath}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plistDomain}.Nudge.Logger</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/log</string>
        <string>stream</string>
        <string>--predicate</string>
        <string>subsystem == 'com.github.macadmins.Nudge'</string>
        <string>--style</string>
        <string>syslog</string>
        <string>--color</string>
        <string>none</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/${plistDomain}.log</string>
</dict>
</plist>
EOF

    /bin/launchctl load -w "${launchDaemonPath}"

else

    scriptResult+="${launchDaemonPath} exists; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge JSON client-side
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${jsonPath} ]]; then

    scriptResult+="Create ${jsonPath} … "
    /usr/bin/touch "${jsonPath}"
    scriptResult+="Created ${jsonPath}; "

    scriptResult+="Write ${jsonPath} … "

    cat <<EOF > "${jsonPath}"
{
    "optionalFeatures": {
        "acceptableApplicationBundleIDs": [
            "us.zoom.xos",
            "com.cisco.webexmeetingsapp"
        ],
        "acceptableAssertionUsage": false,
        "acceptableAssertionApplicationNames": [
            "zoom.us",
            "Meeting Center"
        ],
        "acceptableCameraUsage": false,
        "acceptableScreenSharingUsage": false,
        "aggressiveUserExperience": true,
        "aggressiveUserFullScreenExperience": true,
        "asynchronousSoftwareUpdate": true,
        "attemptToFetchMajorUpgrade": true,
        "attemptToBlockApplicationLaunches": true,
        "blockedApplicationBundleIDs": [
            "com.apple.ColorSyncUtility",
            "com.apple.DigitalColorMeter"
            ],
        "disableSoftwareUpdateWorkflow": false,
        "enforceMinorUpdates": true,
        "terminateApplicationsOnLaunch": true
    },
    "osVersionRequirements": [
        {
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "https://support.apple.com/en-us/HT211896#macos116"
            }
        ],
        "majorUpgradeAppPath": "/Applications/Install macOS Big Sur.app",
        "requiredInstallationDate": "${requiredBigSurInstallationDate}",
        "requiredMinimumOSVersion": "${requiredBigSurMinimumOSVersion}",
        "targetedOSVersionsRule": "11"
        },
        {
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "https://www.apple.com/macos/monterey/"
            }
        ],
        "majorUpgradeAppPath": "/Applications/Install macOS Monterey.app",
        "requiredInstallationDate": "${requiredMontereyInstallationDate}",
        "requiredMinimumOSVersion": "${requiredMontereyMinimumOSVersion}",
        "targetedOSVersionsRule": "12"
        },
        {
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "https://www.apple.com/macos/macos-ventura-preview/"
            }
        ],
        "majorUpgradeAppPath": "/Applications/Install macOS 13 beta.app",
        "requiredInstallationDate": "${requiredMontereyInstallationDate}",
        "requiredMinimumOSVersion": "${requiredVenturaMinimumOSVersion}",
        "targetedOSVersionsRule": "13"
        }
    ],
    "userExperience": {
        "allowGracePeriods": false,
        "allowUserQuitDeferrals": true,
        "allowedDeferrals": 1000000,
        "allowedDeferralsUntilForcedSecondaryQuitButton": 14,
        "approachingRefreshCycle": 6000,
        "approachingWindowTime": 72,
        "elapsedRefreshCycle": 300,
        "gracePeriodInstallDelay": 23,
        "gracePeriodLaunchDelay": 1,
        "gracePeriodPath": "/private/var/db/.AppleSetupDone",
        "imminentRefreshCycle": 600,
        "imminentWindowTime": 24,
        "initialRefreshCycle": 18000,
        "maxRandomDelayInSeconds": 1200,
        "noTimers": false,
        "nudgeRefreshCycle": 60,
        "randomDelay": false
    },
    "userInterface": {
        "actionButtonPath": "jamfselfservice://content?entity=policy&id=1&action=execute",
        "fallbackLanguage": "en",
        "forceFallbackLanguage": false,
        "forceScreenShotIcon": false,
        "iconDarkPath": "/somewhere/logoDark.png",
        "iconLightPath": "/somewhere/logoLight.png",
        "screenShotDarkPath": "/somewhere/screenShotDark.png",
        "screenShotLightPath": "/somewhere/screenShotLight.png",
        "showDeferralCount": true,
        "simpleMode": false,
        "singleQuitButton": false,
        "updateElements": [
        {
            "_language": "en",
            "actionButtonText": "actionButtonText",
            "customDeferralButtonText": "customDeferralButtonText",
            "customDeferralDropdownText": "customDeferralDropdownText",
            "informationButtonText": "informationButtonText",
            "mainContentHeader": "mainContentHeader",
            "mainContentNote": "mainContentNote",
            "mainContentSubHeader": "mainContentSubHeader",
            "mainContentText": "mainContentText \n\nTo perform the update now, click \"actionButtonText,\" review the on-screen instructions by clicking \"More Info…\" then click \"Update Now.\" (Click screenshot below.)\n\nIf you are unable to perform this update now, click \"primaryQuitButtonText\" (which will no longer be visible once the ${deadline} deadline has passed).",
            "mainHeader": "mainHeader",
            "oneDayDeferralButtonText": "oneDayDeferralButtonText",
            "oneHourDeferralButtonText": "oneHourDeferralButtonText",
            "primaryQuitButtonText": "primaryQuitButtonText",
            "secondaryQuitButtonText": "secondaryQuitButtonText",
            "subHeader": "subHeader"
        }
        ]
    }
}
EOF

    scriptResult+="Wrote Nudge JSON file to ${jsonPath}; "

else

    scriptResult+="${jsonPath} exists; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${launchAgentPath} ]]; then

    scriptResult+="Create ${launchAgentPath} … "

    cat <<EOF > "${launchAgentPath}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plistDomain}.Nudge.plist</string>
    <key>LimitLoadToSessionType</key>
    <array>
        <string>Aqua</string>
    </array>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge</string>
        <string>-json-url</string>
        <string>file://${jsonPath}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartCalendarInterval</key>
    <array>
        <dict>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Minute</key>
            <integer>30</integer>
        </dict>
    </array>
</dict>
</plist>
EOF

    scriptResult+="Created ${launchAgentPath}; "

    scriptResult+="Set ${launchAgentPath} file permissions ..."
    /usr/sbin/chown root:wheel "${launchAgentPath}"
    /bin/chmod 644 "${launchAgentPath}"
    /bin/chmod +x "${launchAgentPath}"
    scriptResult+="Set ${launchAgentPath} file permissions; "

else

    scriptResult+="${launchAgentPath} exists"
    scriptResult+="${launchAgentPath} exists; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Load Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# https://github.com/macadmins/nudge/blob/main/build_assets/postinstall-launchagent
# Only enable the LaunchAgent if there is a user logged in, otherwise rely on built in LaunchAgent behavior
if [[ -z "$loggedInUser" ]]; then
    scriptResult+="Did not detect user"
elif [[ "$loggedInUser" == "loginwindow" ]]; then
    scriptResult+="Detected Loginwindow Environment"
elif [[ "$loggedInUser" == "_mbsetupuser" ]]; then
    scriptResult+="Detect SetupAssistant Environment"
elif [[ "$loggedInUser" == "root" ]]; then
    scriptResult+="Detect root as currently logged-in user"
else
    # Unload the LaunchAgent so it can be triggered on re-install
    /bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
    # Kill Nudge just in case (say someone manually opens it and not launched via LaunchAgent
    /usr/bin/killall Nudge
    # Load the LaunchAgent
    /bin/launchctl asuser "${loggedInUserID}" /bin/launchctl load -w "${launchAgentPath}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Goodbye!"

echo "${scriptResult}"

exit 0