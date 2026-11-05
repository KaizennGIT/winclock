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
    fullRepresentation: Cards { now: root.now }

    // Risky part lives in its own file. If it fails, only floatingOk flips.
    Loader {
        id: flyoutLoader
        source: "FloatingFlyout.qml"
        onStatusChanged: if (status === Loader.Error) root.floatingOk = false
    }
    Binding {
        target: flyoutLoader.item
        property: "now"
        value: root.now
        when: flyoutLoader.status === Loader.Ready
    }

    function toggle(anchor) {
        if (floatingOk && flyoutLoader.status === Loader.Ready) {
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
                text: Qt.formatTime(root.now, "h:mm AP")
            }
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(root.now, "M/d/yyyy")
            }
        }
    }
}
