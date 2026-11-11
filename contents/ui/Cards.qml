import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: content
    property date now: new Date()
    property var prefs          // the widget root; gives access to the settings

    // Extra transparent space on each side. The floating flyout uses this to
    // keep the cards off the panel. All 0 in the normal popup.
    property int gapTop: 0
    property int gapBottom: 0
    property int gapLeft: 0
    property int gapRight: 0

    readonly property int widthUnits: prefs ? Math.max(20, Math.min(60, prefs.cfgFlyoutWidth)) : 24
    readonly property int pad: Kirigami.Units.largeSpacing
    implicitWidth: Kirigami.Units.gridUnit * widthUnits + pad * 2 + gapLeft + gapRight
    implicitHeight: Kirigami.Units.gridUnit * 34 + pad * 2 + gapTop + gapBottom

    // Plasma sizes the window from these hints, so width changes apply live
    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: implicitHeight

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: content.pad + content.gapLeft
        anchors.rightMargin: content.pad + content.gapRight
        anchors.topMargin: content.pad + content.gapTop
        anchors.bottomMargin: content.pad + content.gapBottom
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
                id: notif
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                source: "NotificationPane.qml"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            // as tall as the calendar needs; shrinks when it is collapsed
            Layout.preferredHeight: cal.item
                ? cal.item.implicitHeight + Kirigami.Units.smallSpacing * 2
                : Kirigami.Units.gridUnit * 19
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
        target: notif.item
        property: "prefs"
        value: content.prefs
        when: notif.status === Loader.Ready
    }
    Binding {
        target: cal.item
        property: "now"
        value: content.now
        when: cal.status === Loader.Ready
    }
    Binding {
        target: cal.item
        property: "prefs"
        value: content.prefs
        when: cal.status === Loader.Ready
    }
}
