
function get_vpn_names() {
    osascript -e '
    tell application "System Events"
        tell process "SystemUIServer"
            set vpnMenu to (menu bar item 1 of menu bar 1 where description is "VPN")
            tell vpnMenu to click
            delay 1
            set vpnMenuItems to menu items of menu 1 of vpnMenu
            set vpnNames to {}
            repeat with vpnItem in vpnMenuItems
                set vpnName to name of vpnItem
                if vpnName contains "connect" then
                    set end of vpnNames to vpnName
                end if
            end repeat
            tell vpnMenu to click   
            return vpnNames
        end tell
    end tell
' | tr ',' '\n'
}


function lazy_connect() {
  local vpn_name=$VPN_NAME
  local autofill=true
  local password=$OTP
  osascript <<EOF
    on connectVpn(vpnName, password, autofill)
      tell application "System Events"
        tell process "SystemUIServer"
          set vpnMenu to (menu bar item 1 of menu bar 1 where description is "VPN")
          tell vpnMenu to click
          try
            click menu item vpnName of menu 1 of vpnMenu
            if autofill is equal to "true" and not (vpnName contains "Disconnect") then
              delay 2
              keystroke password
              delay 1
              keystroke return
            end if
          on error errorStr
            if errorStr does not contain "Can't get menu item" and errorStr does not contain vpnName then
              display dialog errorStr
            end if
          end try
        end tell
      end tell
    end connectVpn

    connectVpn("$vpn_name", "$password", "$autofill")
EOF
}

cmd=$(basename "$0")

if [[ $1 = "hello-world" ]]
then  
    echo "hello world"

elif [[ $1 = "int-tag" ]]
then
    DATE="v0.0.$(date '+%Y%m%d%H%M%S')"
    echo $DATE
    echo $DATE | pbcopy
elif [[ $1 = "vpn-int" ]]
then
    OTP=$(/opt/homebrew/bin/oathtool --totp --base32 `security find-generic-password -a easy-lazy-connect -w 2>/dev/null | tr -d '\n'`)
    VPN_NAME="Connect GOJEK INTEGRATION VPN"
    lazy_connect
elif [[ $1 = "vpn-prod" ]]
then
    OTP=$(/opt/homebrew/bin/oathtool --totp --base32 `security find-generic-password -a easy-lazy-connect -w 2>/dev/null | tr -d '\n'`)
    VPN_NAME="Connect GOJEK PRODUCTION VPN"
    lazy_connect
elif [[ $1 = "vpn-list" ]]
then
    OTP=$(/opt/homebrew/bin/oathtool --totp --base32 `security find-generic-password -a easy-lazy-connect -w 2>/dev/null | tr -d '\n'`)
    VPN_LIST=$(echo "$(get_vpn_names)" | jq -R . | jq -s . | jq '{app: .}')

    VPN_NAME=$(echo "$VPN_LIST" | jq -r '.app[]' | sort -u | fzf -q "$qapp" --reverse --height 10)
    [ -z "$VPN_NAME" ] && exit 1
    echo "Connecting to VPN: $VPN_NAME"
    lazy_connect
elif [[ $1 = "java-versions" ]]
then
  echo $(/usr/libexec/java_home -V)
elif [[ $1 = "open-goland" ]]
then
  open -na "GoLand.app" --args ~/Gojek/$2/
elif [[ $1 = "upload-int" ]]
then
    kssh scp /Users/harikeshverma03/personal/harikeshverma03/cli/combined_script.sh 10.224.104.26:
fi
if [[ $1 = "set-ns" ]]
then
  kubectl config set-context --current --namespace=$2
elif [[ $1 = "get-all" ]]
then
    if [ -z "$2" ]; then
        kubectl get all | column -t | awk '
        NR==1 {print; next}
        /pod/ {print "\033[32m" $0 "\033[39m"; next}
        /service/ {print "\033[34m" $0 "\033[39m"; next}
        /deployment/ {print "\033[35m" $0 "\033[39m"; next}
        /replicaset/ {print "\033[36m" $0 "\033[39m"; next}
        {print}'
    else
        kubectl get all | grep $2 | column -t | awk '
        NR==1 {print; next}
        /pod/ {print "\033[32m" $0 "\033[39m"; next}
        /service/ {print "\033[34m" $0 "\033[39m"; next}
        /deployment/ {print "\033[35m" $0 "\033[39m"; next}
        /replicaset/ {print "\033[36m" $0 "\033[39m"; next}
        {print}'
    fi
elif [[ $1 = "describe" ]]
then
    if [ -z "$2" ]; then
        echo "Please provide the resource type (e.g., pods, deploy)"
        exit 1
    fi

    if [ -z "$3" ]; then
        RESOURCE_LIST=$(kubectl get $2 -o wide | column -t | fzf --reverse --height 10)
    else
        RESOURCE_LIST=$(kubectl get $2 -o wide | grep $3 | column -t | fzf --reverse --height 10)
    fi
    [ -z "$RESOURCE_LIST" ] && exit 1
    RESOURCE_NAME=$(echo $RESOURCE_LIST | awk '{print $1}')
    echo "Describing $2: $RESOURCE_NAME"
    kubectl describe $2 $RESOURCE_NAME
elif [[ $1 = "ssh" ]]
then
    if [ -z "$2" ]; then
        RESOURCE_LIST=$(kubectl get pods -o wide | column -t | fzf --reverse --height 10)
    else
        RESOURCE_LIST=$(kubectl get pods -o wide | grep $2 | column -t | fzf --reverse --height 10)
    fi
    [ -z "$RESOURCE_LIST" ] && exit 1
    RESOURCE_NAME=$(echo $RESOURCE_LIST | awk '{print $1}')
    echo "Running sh command in pod: $RESOURCE_NAME"
    kubectl exec -it $RESOURCE_NAME -- sh
elif [[ $1 = "logs" ]]
then
    if [ -z "$2" ]; then
        RESOURCE_LIST=$(kubectl get pods -o wide | column -t | fzf --reverse --height 10)
    else
        RESOURCE_LIST=$(kubectl get pods -o wide | grep $2 | column -t | fzf --reverse --height 10)
    fi
    [ -z "$RESOURCE_LIST" ] && exit 1
    RESOURCE_NAME=$(echo $RESOURCE_LIST | awk '{print $1}')
    echo "Fetching logs for pod: $RESOURCE_NAME"
    kubectl logs -f $RESOURCE_NAME
fi
