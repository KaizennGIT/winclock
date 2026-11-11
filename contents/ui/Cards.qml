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

    // Themes. plasma = either Plasma theme (one flat panel instead of two cards).
    // classic = Classic Plasma: KDE's own popup size, docked, drawn inside Plasma's popup frame.
    readonly property bool plasma: prefs ? prefs.cfgPlasmaLook : false
    readonly property bool classic: prefs ? prefs.cfgClassic : false
    readonly property int innerMargin: classic ? 0 : (plasma ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing)
    readonly property int sideInset: classic ? 0 : Kirigami.Units.largeSpacing

    // Classic Plasma has a fixed width (about the size of KDE's calendar popup)
    readonly property int widthUnits: classic ? 34 : (prefs ? Math.max(20, Math.min(60, prefs.cfgFlyoutWidth)) : 24)
    readonly property int pad: Kirigami.Units.largeSpacing
    // Classic Plasma: the calendar is as tall as it needs, plus a fixed notification area
    readonly property int notifAreaHeight: Kirigami.Units.gridUnit * 11
    readonly property int calSectionHeight: cal.item
        ? cal.item.implicitHeight + innerMargin * 2
        : Kirigami.Units.gridUnit * 27
    // Same, but as if the calendar were open. The flyout keeps this size when the calendar
    // is folded away, and the notification area grows to fill the freed space.
    readonly property int calFullHeight: cal.item
        ? cal.item.fullHeight + innerMargin * 2
        : Kirigami.Units.gridUnit * 27
    implicitWidth: Kirigami.Units.gridUnit * widthUnits + pad * 2 + gapLeft + gapRight
    implicitHeight: classic
        ? notifAreaHeight + 1 + calFullHeight + pad * 2 + gapTop + gapBottom
        : Kirigami.Units.gridUnit * (plasma ? 36 : 34) + pad * 2 + gapTop + gapBottom

    // Plasma sizes the window from these hints, so width changes apply live
    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: implicitHeight

    // The single background panel used by Modern Plasma (Classic Plasma uses Plasma's own popup frame)
    Rectangle {
        visible: content.plasma && !content.classic
        anchors.fill: body
        radius: 8
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
    }

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.leftMargin: content.pad + content.gapLeft
        anchors.rightMargin: content.pad + content.gapRight
        anchors.topMargin: content.pad + content.gapTop
        anchors.bottomMargin: content.pad + content.gapBottom
        spacing: content.plasma ? 0 : Kirigami.Units.largeSpacing

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 8
            radius: 10
            color: content.plasma ? "transparent" : Kirigami.Theme.backgroundColor
            border.width: content.plasma ? 0 : 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            Loader {
                id: notif
                anchors.fill: parent
                anchors.margins: content.innerMargin
                source: "NotificationPane.qml"
            }
        }

        // thin line between notifications and the clock/calendar (Plasma style only)
        Kirigami.Separator {
            visible: content.plasma
            Layout.fillWidth: true
            Layout.leftMargin: content.sideInset
            Layout.rightMargin: content.sideInset
        }

        Rectangle {
            Layout.fillWidth: true
            // as tall as the calendar needs; shrinks when it is collapsed
            Layout.preferredHeight: cal.item
                ? content.calSectionHeight
                : Kirigami.Units.gridUnit * 19
            radius: 10
            color: content.plasma ? "transparent" : Kirigami.Theme.backgroundColor
            border.width: content.plasma ? 0 : 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            Loader {
                id: cal
                anchors.fill: parent
                anchors.margins: content.innerMargin
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
