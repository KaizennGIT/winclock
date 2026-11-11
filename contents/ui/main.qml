import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property date now: new Date()
    property bool floatingOk: true
    property double requestedAt: 0

    // Settings (see contents/config/main.xml). The "||" fallbacks make sure an
    // empty value can never leave the panel clock blank.
    readonly property string cfgTimeFormat: Plasmoid.configuration.timeFormat || "h:mm AP"
    readonly property string cfgDateFormat: Plasmoid.configuration.dateFormat || "M/d/yyyy"
    readonly property bool cfgShowDate: Plasmoid.configuration.showDate
    readonly property bool cfgFlyout24h: Plasmoid.configuration.flyout24h
    readonly property bool cfgFlyoutSeconds: Plasmoid.configuration.flyoutSeconds
    readonly property bool cfgFloating: Plasmoid.configuration.floating
    readonly property int cfgFlyoutWidth: Plasmoid.configuration.flyoutWidth
    readonly property bool cfgNotifAnimations: Plasmoid.configuration.notifAnimations

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    preferredRepresentation: compactRepresentation
    toolTipMainText: Qt.formatDate(now, "dddd")
    toolTipSubText: Qt.formatDate(now, "MMMM d, yyyy")

    // Fallback: Plasma's normal popup, same cards
    fullRepresentation: Cards { now: root.now; prefs: root }

    // Risky part lives in its own file. If it fails, only floatingOk flips.
    Loader {
        id: flyoutLoader
        source: "FloatingFlyout.qml"
        onLoaded: item.prefs = root
        onStatusChanged: if (status === Loader.Error) root.floatingOk = false
    }
    Binding {
        target: flyoutLoader.item
        property: "now"
        value: root.now
        when: flyoutLoader.status === Loader.Ready
    }

    function toggle(anchor) {
        if (cfgFloating && floatingOk && flyoutLoader.status === Loader.Ready) {
            const f = flyoutLoader.item
            // clicking the clock deactivates the dialog first; don't instantly reopen
            if (!f.open && Date.now() - f.lastClosed < 250) return
            f.anchorItem = anchor
            f.panelLocation = Plasmoid.location
            f.open = !f.open
            if (f.open) {
                requestedAt = Date.now()
                watchdog.restart()
            }
        } else {
            root.expanded = !root.expanded
        }
    }

    // asked to open but never appeared -> switch to the stock popup
    Timer {
        id: watchdog
        interval: 600
        onTriggered: {
            const f = flyoutLoader.item
            if (f && !f.open && f.lastClosed < root.requestedAt) {
                root.floatingOk = false
                root.expanded = true
            }
        }
    }

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        Layout.minimumWidth: col.implicitWidth + Kirigami.Units.largeSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        onClicked: root.toggle(compact)

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 0
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(root.now, root.cfgTimeFormat)
            }
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.cfgShowDate
                text: Qt.formatDate(root.now, root.cfgDateFormat)
            }
        }
    }
}
