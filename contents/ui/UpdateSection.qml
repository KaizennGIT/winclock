import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

// "Check for updates" and "Install update" for the settings page.
// Nothing runs until you press a button: no automatic network requests.
ColumnLayout {
    id: root
    spacing: Kirigami.Units.smallSpacing

    readonly property string repoUrl: "https://github.com/KaizennGIT/winclock.git"

    // idle | checking | upToDate | available | unknown | localBuild |
    // error | installing | installed | failed
    property string phase: "idle"
    property string kind: ""          // which command is running: check, install, restart
    property string installedSha: ""
    property string latestSha: ""
    property string log: ""

    readonly property bool busy: phase === "checking" || phase === "installing"
    readonly property bool canInstall: phase === "available" || phase === "unknown"
                                       || phase === "localBuild" || phase === "failed"

    function abbrev(sha) {
        return sha.slice(0, 7)
    }

    // Runs a shell script (it must not contain single quotes). Stderr is
    // merged into stdout.
    function runScript(script) {
        // the trailing comment makes every command string unique, so the
        // engine runs it again each time
        runner.connectSource("sh -c 'exec 2>&1; " + script + "' # " + Date.now())
    }

    function check() {
        phase = "checking"
        kind = "check"
        log = ""
        // prints "<installed commit>|" then GitHub's latest commit
        runScript(`b="\${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/com.kaizen.winclock/contents/BUILD"; `
                  + `echo "$(cat "$b" 2>/dev/null)|"; `
                  + `git ls-remote ${repoUrl} HEAD | cut -f1`)
    }

    function install() {
        phase = "installing"
        kind = "install"
        log = ""
        // download the latest version to a temporary folder, run its
        // installer, then delete the folder
        runScript(`d=$(mktemp -d) || exit 1; `
                  + `git clone --depth 1 ${repoUrl} "$d/winclock" && (cd "$d/winclock" && bash ./install.sh); `
                  + `r=$?; rm -rf "$d"; exit $r`)
    }

    function restartPanel() {
        kind = "restart"
        // setsid keeps the restart alive when the panel (and this dialog) closes
        runner.connectSource("setsid sh -c 'sleep 1; kquitapp6 plasmashell; sleep 2; kstart plasmashell' >/dev/null 2>&1 & # " + Date.now())
    }

    function finished(code, out) {
        if (kind === "check") {
            const i = out.indexOf("|")
            const cur = i >= 0 ? out.slice(0, i).trim() : ""
            const rem = i >= 0 ? out.slice(i + 1).trim() : out.trim()
            if (!/^[0-9a-f]{40}$/.test(rem)) {
                log = rem
                phase = "error"
                return
            }
            latestSha = rem
            installedSha = cur.replace("+local", "")
            if (cur === "") {
                phase = "unknown"
            } else if (cur.endsWith("+local")) {
                phase = "localBuild"
            } else if (installedSha === rem) {
                phase = "upToDate"
            } else {
                phase = "available"
            }
        } else if (kind === "install") {
            log = out.trim().split("\n").slice(-6).join("\n")
            phase = code === 0 ? "installed" : "failed"
        }
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            root.finished(data["exit code"], data["stdout"] || "")
        }
    }

    QQC2.Label {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        wrapMode: Text.Wrap
        text: {
            switch (root.phase) {
            case "checking":   return "Checking GitHub..."
            case "upToDate":   return "You're up to date."
            case "available":  return "An update is available."
            case "unknown":    return "Can't tell which version is installed (it was installed before the updater existed). Installing the update will fix that."
            case "localBuild": return "You're running a locally modified build. Installing the update replaces it with the version on GitHub."
            case "error":      return "Couldn't reach GitHub. Check your connection and try again."
            case "installing": return "Installing the update..."
            case "installed":  return "Update installed. Restart the panel to start using it."
            case "failed":     return "The update failed."
            default:           return "Check whether a newer version is on GitHub."
            }
        }
    }
    QQC2.Label {
        visible: root.installedSha !== "" || root.latestSha !== ""
        opacity: 0.7
        font: Kirigami.Theme.smallFont
        text: "Installed: " + (root.installedSha !== "" ? root.abbrev(root.installedSha) : "unknown")
              + "   Latest: " + (root.latestSha !== "" ? root.abbrev(root.latestSha) : "unknown")
    }
    QQC2.Label {
        visible: root.log !== "" && (root.phase === "error" || root.phase === "failed")
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        wrapMode: Text.Wrap
        opacity: 0.7
        font: Kirigami.Theme.smallFont
        text: root.log
    }

    RowLayout {
        spacing: Kirigami.Units.smallSpacing
        QQC2.Button {
            text: "Check for updates"
            icon.name: "view-refresh"
            enabled: !root.busy
            onClicked: root.check()
        }
        QQC2.Button {
            text: "Install update"
            icon.name: "install"
            enabled: root.canInstall
            onClicked: root.install()
        }
    }
    QQC2.Button {
        visible: root.phase === "installed"
        text: "Restart panel now"
        icon.name: "system-reboot"
        onClicked: root.restartPanel()
    }
    QQC2.Label {
        visible: root.phase === "installed"
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        wrapMode: Text.Wrap
        opacity: 0.7
        font: Kirigami.Theme.smallFont
        text: "The panel flickers for a couple of seconds while it restarts. This settings window will close."
    }
}
