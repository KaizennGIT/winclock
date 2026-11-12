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

    // Plasma themes (setting): flat look like KDE's default calendar popup.
    // classic = Classic Plasma: bigger text and cells, matching KDE's real popup.
    readonly property bool plasma: prefs ? prefs.cfgPlasmaLook : false
    readonly property bool classic: prefs ? prefs.cfgClassic : false
    readonly property real textScale: classic ? 1.1 : 1.0
    readonly property int edgeInset: classic ? 0 : Kirigami.Units.largeSpacing
    // KDE shows the hour with a leading zero and AM/PM in the same size
    readonly property string plasmaClockFormat: (use24h ? "HH:mm" : "hh:mm") + (showSecs ? ":ss" : "") + (use24h ? "" : " AP")

    // which month is being shown (starts on the current month)
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()

    // What the calendar area shows: 0 = days, 1 = months of viewYear, 2 = a block of years.
    // Click the month title to go 0 -> 1 -> 2; pick a year/month to come back down.
    property int viewMode: 0
    // first year of the 10-year block shown in the years view
    readonly property int decadeStart: Math.floor(viewYear / 10) * 10

    // Row heights, shared by the day grid and the month/year grid so the area keeps
    // the same height in every view (otherwise the flyout would jump around).
    readonly property real weekRowH: Kirigami.Units.gridUnit * (classic ? 2.7 : (plasma ? 1.8 : 1.6))
    readonly property real cellRowH: Kirigami.Units.gridUnit * (classic ? 2.7 : 2)
    readonly property real gridHeight: weekRowH + cellRowH * 6

    implicitHeight: col.implicitHeight
    // Height with the month panel open, even while it is folded away. Cards sizes the
    // flyout from this, so folding the calendar frees room for the notifications
    // instead of shrinking the whole flyout.
    readonly property real fullHeight: col.implicitHeight
        + (expanded ? 0 : monthPanel.Layout.preferredHeight + col.spacing)

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    function clampYear(y) {
        return Math.max(100, Math.min(9999, y))   // JS dates treat 0-99 as 1900-1999
    }

    // the up/down arrows: a month, a year, or ten years, depending on the view
    function shiftView(delta) {
        if (viewMode === 0) {
            shiftMonth(delta)
        } else if (viewMode === 1) {
            viewYear = clampYear(viewYear + delta)
        } else {
            viewYear = clampYear(viewYear + delta * 10)
        }
    }

    // click the title: days -> months -> years
    function drillUp() {
        if (viewMode < 2) {
            viewMode = viewMode + 1
        }
    }

    function pickMonth(m) {
        viewMonth = m
        viewMode = 0
    }

    function pickYear(y) {
        viewYear = y
        viewMode = 1
    }

    // the calendar button (Plasma themes): days -> months -> years -> back to today
    function cycleView() {
        if (viewMode < 2) {
            viewMode = viewMode + 1
        } else {
            goToday()
        }
    }

    // True while the flyout is open. Every time it opens or closes, go back to the
    // current month so coming back later always starts on today.
    property bool active: false
    onActiveChanged: goToday()

    // back to today: current month, day view
    function goToday() {
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
        viewMode = 0
    }

    // The first cell of the 6x7 grid: the first day of the month, moved back
    // to the start of its week.
    readonly property var gridStart: {
        const first = new Date(viewYear, viewMonth, 1)
        const firstDow = Qt.locale().firstDayOfWeek % 7
        let offset = (first.getDay() - firstDow + 7) % 7
        if (plasma && offset === 0) {
            offset = 7   // like KDE: a first row of the previous month
        }
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
            Layout.leftMargin: root.edgeInset
            Layout.rightMargin: root.classic ? 0 : Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    PlasmaComponents.Label {
                        text: Qt.formatTime(root.now, root.plasma ? root.plasmaClockFormat : root.clockFormat)
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * (root.classic ? 3 : (root.plasma ? 2.6 : 2))
                        font.weight: root.plasma ? Font.Light : Font.DemiBold
                        Layout.alignment: Qt.AlignBaseline
                    }
                    PlasmaComponents.Label {
                        text: Qt.formatTime(root.now, "AP")
                        visible: !root.use24h && !root.plasma
                        opacity: 0.8
                        Layout.alignment: Qt.AlignBaseline
                    }
                }
                PlasmaComponents.Label {
                    text: root.plasma ? Qt.formatDate(root.now, "dddd d MMMM yyyy") : Qt.formatDate(root.now, "dddd, MMMM d")
                    opacity: root.plasma ? 0.9 : 0.7
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * (root.classic ? 1.2 : 1.0)
                    // click today's date to jump back to the current month
                    TapHandler { onTapped: root.goToday() }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: root.expanded ? "go-down-symbolic" : "go-up-symbolic"
                Layout.alignment: Qt.AlignTop
                onClicked: root.expanded = !root.expanded
            }
        }

        // thin line under the header (Plasma themes only, while the calendar is open)
        Kirigami.Separator {
            visible: root.plasma && root.expanded
            Layout.fillWidth: true
            Layout.leftMargin: root.edgeInset
            Layout.rightMargin: root.edgeInset
            Layout.topMargin: root.classic ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.smallSpacing
            Layout.bottomMargin: root.classic ? Kirigami.Units.largeSpacing : 0
        }

        // ---- month panel (folded away with the arrow in the header) ----
        Rectangle {
            id: monthPanel
            visible: root.expanded
            Layout.fillWidth: true
            Layout.preferredHeight: panelCol.implicitHeight + (root.classic ? 0 : Kirigami.Units.smallSpacing * 2)
            radius: 6
            color: root.plasma ? "transparent" : Kirigami.Theme.alternateBackgroundColor

            ColumnLayout {
                id: panelCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: root.classic ? 0 : Kirigami.Units.smallSpacing
                }
                spacing: 0

                // month name + up/down arrows
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: root.classic ? 0 : Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * root.textScale
                        text: root.viewMode === 0
                            ? Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                            : root.viewMode === 1
                                ? String(root.viewYear)
                                : root.decadeStart + " \u2013 " + (root.decadeStart + 9)
                        font.weight: root.plasma ? Font.Normal : Font.DemiBold
                        // click the title: days -> months -> years
                        TapHandler { onTapped: root.drillUp() }
                        HoverHandler { cursorShape: root.viewMode < 2 ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "go-up-symbolic"
                        onClicked: root.shiftView(-1)
                    }
                    PlasmaComponents.ToolButton {
                        visible: root.plasma
                        icon.name: "view-calendar"
                        onClicked: root.cycleView()
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "go-down-symbolic"
                        onClicked: root.shiftView(1)
                    }
                }

                // weekday names (first 7 cells) + 42 day cells
                GridLayout {
                    id: dayGrid
                    visible: root.viewMode === 0
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 0
                    uniformCellWidths: true

                    Repeater {
                        model: 7
                        delegate: PlasmaComponents.Label {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * (root.classic ? 2.7 : (root.plasma ? 1.8 : 1.6))
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * root.textScale
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: root.plasma
                                ? Qt.formatDate(root.cellDate(index), "ddd")
                                : Qt.formatDate(root.cellDate(index), "ddd").substring(0, 2)
                            font.weight: root.plasma ? Font.Bold : Font.DemiBold
                            opacity: root.plasma ? 1.0 : 0.8
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
                            Layout.preferredHeight: Kirigami.Units.gridUnit * (root.classic ? 2.7 : 2)

                            // Windows style: solid circle. Plasma style: rounded box with
                            // a soft fill and an outline, like KDE's own calendar.
                            Rectangle {
                                anchors.centerIn: parent
                                width: root.plasma ? parent.width - 4 : Kirigami.Units.gridUnit * 1.8
                                height: root.plasma ? parent.height - 4 : width
                                radius: root.plasma ? 4 : width / 2
                                color: !cell.isToday ? "transparent"
                                    : root.plasma
                                        ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35)
                                        : Kirigami.Theme.highlightColor
                                border.width: root.plasma && cell.isToday ? 1 : 0
                                border.color: Kirigami.Theme.highlightColor
                            }
                            PlasmaComponents.Label {
                                anchors.centerIn: parent
                                text: cell.d.getDate()
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * root.textScale
                                font.bold: root.plasma && cell.isToday
                                color: root.plasma || !cell.isToday ? Kirigami.Theme.textColor : Kirigami.Theme.highlightedTextColor
                                opacity: cell.inMonth || cell.isToday ? 1.0 : (root.plasma ? 0.3 : 0.4)
                            }
                        }
                    }
                }

                // months (view 1) or years (view 2): 4 rows of 3
                GridLayout {
                    id: pickGrid
                    visible: root.viewMode !== 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.gridHeight
                    columns: 3
                    columnSpacing: 0
                    rowSpacing: 0
                    uniformCellWidths: true

                    Repeater {
                        model: 12
                        delegate: Item {
                            id: pick
                            readonly property bool isMonths: root.viewMode === 1
                            // years view: 10 years of the block plus one dimmed year on each side
                            readonly property int value: isMonths ? index : root.decadeStart - 1 + index
                            readonly property bool isCurrent: isMonths
                                ? (root.viewYear === root.now.getFullYear() && value === root.now.getMonth())
                                : value === root.now.getFullYear()
                            readonly property bool inRange: isMonths || (index >= 1 && index <= 10)

                            Layout.fillWidth: true
                            Layout.preferredHeight: root.gridHeight / 4

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                radius: root.plasma ? 4 : 6
                                color: pick.isCurrent
                                    ? (root.plasma
                                        ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35)
                                        : Kirigami.Theme.highlightColor)
                                    : (pickHover.hovered
                                        ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                        : "transparent")
                                border.width: root.plasma && pick.isCurrent ? 1 : 0
                                border.color: Kirigami.Theme.highlightColor
                            }
                            PlasmaComponents.Label {
                                anchors.centerIn: parent
                                text: pick.isMonths
                                    ? Qt.formatDate(new Date(2000, pick.value, 1), "MMM")
                                    : String(pick.value)
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * root.textScale
                                font.bold: root.plasma && pick.isCurrent
                                color: root.plasma || !pick.isCurrent ? Kirigami.Theme.textColor : Kirigami.Theme.highlightedTextColor
                                opacity: pick.inRange || pick.isCurrent ? 1.0 : 0.4
                            }
                            HoverHandler { id: pickHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: pick.isMonths ? root.pickMonth(pick.value) : root.pickYear(pick.value)
                            }
                        }
                    }
                }
            }
        }
    }
}
