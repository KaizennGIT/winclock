import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: root
    property date now: new Date()
    property bool expanded: true

    // set by main.qml: gives access to the settings
    property var prefs
    readonly property bool use24h: prefs ? prefs.cfgFlyout24h : false
    readonly property bool showSecs: prefs ? prefs.cfgFlyoutSeconds : true
    readonly property string clockFormat: (use24h ? "HH:mm" : "h:mm") + (showSecs ? ":ss" : "")

    // which month is being shown (starts on the current month)
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()

    implicitHeight: col.implicitHeight

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    function goToday() {
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
    }

    // The first cell of the 6x7 grid: the first day of the month, moved back
    // to the start of its week.
    readonly property var gridStart: {
        const first = new Date(viewYear, viewMonth, 1)
        const firstDow = Qt.locale().firstDayOfWeek % 7
        const offset = (first.getDay() - firstDow + 7) % 7
        return new Date(viewYear, viewMonth, 1 - offset)
    }

    function cellDate(i) {
        return new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + i)
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // ---- big time / date header ----
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    PlasmaComponents.Label {
                        text: Qt.formatTime(root.now, root.clockFormat)
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignBaseline
                    }
                    PlasmaComponents.Label {
                        text: Qt.formatTime(root.now, "AP")
                        visible: !root.use24h
                        opacity: 0.8
                        Layout.alignment: Qt.AlignBaseline
                    }
                }
                PlasmaComponents.Label {
                    text: Qt.formatDate(root.now, "dddd, MMMM d")
                    opacity: 0.7
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: root.expanded ? "go-down-symbolic" : "go-up-symbolic"
                Layout.alignment: Qt.AlignTop
                onClicked: root.expanded = !root.expanded
            }
        }

        // ---- month panel (hidden when collapsed) ----
        Rectangle {
            visible: root.expanded
            Layout.fillWidth: true
            Layout.preferredHeight: panelCol.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: 6
            color: Kirigami.Theme.alternateBackgroundColor

            ColumnLayout {
                id: panelCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Kirigami.Units.smallSpacing
                }
                spacing: 0

                // month name + up/down arrows
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                        font.weight: Font.DemiBold
                        // click the month name to jump back to the current month
                        TapHandler { onTapped: root.goToday() }
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "go-up-symbolic"
                        onClicked: root.shiftMonth(-1)
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "go-down-symbolic"
                        onClicked: root.shiftMonth(1)
                    }
                }

                // weekday names (first 7 cells) + 42 day cells
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 0
                    uniformCellWidths: true

                    Repeater {
                        model: 7
                        delegate: PlasmaComponents.Label {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: Qt.formatDate(root.cellDate(index), "ddd").substring(0, 2)
                            font.weight: Font.DemiBold
                            opacity: 0.8
                        }
                    }

                    Repeater {
                        model: 42
                        delegate: Item {
                            id: cell
                            readonly property var d: root.cellDate(index)
                            readonly property bool inMonth: d.getMonth() === root.viewMonth
                            readonly property bool isToday: d.getFullYear() === root.now.getFullYear()
                                && d.getMonth() === root.now.getMonth()
                                && d.getDate() === root.now.getDate()

                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                            Rectangle {
                                anchors.centerIn: parent
                                width: Kirigami.Units.gridUnit * 1.8
                                height: width
                                radius: width / 2
                                color: cell.isToday ? Kirigami.Theme.highlightColor : "transparent"
                            }
                            PlasmaComponents.Label {
                                anchors.centerIn: parent
                                text: cell.d.getDate()
                                color: cell.isToday ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                opacity: cell.inMonth || cell.isToday ? 1.0 : 0.4
                            }
                        }
                    }
                }
            }
        }
    }
}
