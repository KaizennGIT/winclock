import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: content
    property date now: new Date()
    readonly property int pad: Kirigami.Units.largeSpacing
    implicitWidth: Kirigami.Units.gridUnit * 24 + pad * 2
    implicitHeight: Kirigami.Units.gridUnit * 34 + pad * 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: content.pad
        spacing: Kirigami.Units.largeSpacing

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 8
            radius: 10
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            Loader {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                source: "NotificationPane.qml"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 19
            radius: 10
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            Loader {
                id: cal
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                source: "CalendarPane.qml"
            }
        }
    }

    Binding {
        target: cal.item
        property: "now"
        value: content.now
        when: cal.status === Loader.Ready
    }
}
