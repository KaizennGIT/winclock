import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    preferredRepresentation: compactRepresentation
    toolTipMainText: Qt.formatDate(now, "dddd")
    toolTipSubText: Qt.formatDate(now, "MMMM d, yyyy")

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        Layout.minimumWidth: col.implicitWidth + Kirigami.Units.largeSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        onClicked: root.expanded = !root.expanded

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

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: Kirigami.Units.gridUnit * 28
        Layout.preferredHeight: Kirigami.Units.gridUnit * 34
        spacing: Kirigami.Units.largeSpacing

        // Card 1: notifications
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 8
            radius: 10
            color: Kirigami.Theme.alternateBackgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

            Loader {
                id: notifLoader
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                source: "NotificationPane.qml"

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: notifLoader.status === Loader.Error
                    text: "Notifications failed to load"
                }
            }
        }

        // Card 2: calendar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 19
            radius: 10
            color: Kirigami.Theme.alternateBackgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

            Loader {
                id: cal
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                source: "CalendarPane.qml"

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: cal.status === Loader.Error
                    text: "Calendar failed to load"
                }
            }
        }

        Binding {
            target: cal.item
            property: "now"
            value: root.now
            when: cal.status === Loader.Ready
        }
    }
}
