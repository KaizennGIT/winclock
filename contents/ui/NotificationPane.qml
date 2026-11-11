import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

ColumnLayout {
    id: pane
    spacing: Kirigami.Units.smallSpacing

    // set by Cards.qml: gives access to the settings
    property var prefs
    readonly property bool animationsEnabled: prefs ? prefs.cfgNotifAnimations : true
    // Plasma-style look (setting): flat bordered rows that match KDE's calendar
    readonly property bool plasma: prefs ? prefs.cfgPlasmaLook : false
    // Classic Plasma: content runs edge to edge so it lines up with the calendar grid
    readonly property bool classic: prefs ? prefs.cfgClassic : false

    NotificationManager.Notifications {
        id: notifModel
        showExpired: true
        showDismissed: true
        showJobs: false
        urgencies: NotificationManager.Notifications.CriticalUrgency
                 | NotificationManager.Notifications.NormalUrgency
                 | NotificationManager.Notifications.LowUrgency

        // Per-app grouping. To turn grouping off, delete these two lines.
        groupMode: NotificationManager.Notifications.GroupApplicationsFlat
        groupLimit: 1
    }

    // ---- layout knobs: raise these to space things out more ----
    readonly property int textSpacing: Kirigami.Units.smallSpacing      // gap between lines of text in a card
    readonly property int cardPadding: Kirigami.Units.smallSpacing * 2  // space between card edge and content

    // Bumped whenever the model changes, so the group lookups below refresh
    property int rev: 0
    Connections {
        target: notifModel
        function onDataChanged() { pane.rev++ }
        function onRowsInserted() { pane.rev++ }
        function onRowsRemoved() { pane.rev++ }
        function onLayoutChanged() { pane.rev++ }
        function onModelReset() { pane.rev++ }
    }

    // Group header delegates listen for this and flip their own expanded state
    signal toggleGroupRequested(int row)

    function roleAt(row, role) {
        return notifModel.data(notifModel.index(row, 0), role)
    }
    // Row of the group header that sits above this child row, or -1
    function groupHeaderRow(row) {
        for (let i = row - 1; i >= 0; i--) {
            if (roleAt(i, NotificationManager.Notifications.IsGroupRole) === true) {
                return i
            }
        }
        return -1
    }
    // True if the next row is not another child of the same group
    function isLastInGroup(row) {
        if (row + 1 >= list.count) {
            return true
        }
        return roleAt(row + 1, NotificationManager.Notifications.IsInGroupRole) !== true
    }

    // Plasma's notification settings; this is where Do Not Disturb lives
    NotificationManager.Settings { id: dndSettings }

    readonly property bool dndActive: {
        const u = dndSettings.notificationsInhibitedUntil
        const timed = !!u && !isNaN(u.getTime()) && u.getTime() > Date.now()
        return timed || dndSettings.notificationsInhibitedByApplication
    }

    function toggleDnd() {
        if (dndActive) {
            dndSettings.notificationsInhibitedUntil = undefined
            dndSettings.revokeApplicationInhibitions()
        } else {
            // "until turned off" = one year from now
            const d = new Date()
            d.setFullYear(d.getFullYear() + 1)
            dndSettings.notificationsInhibitedUntil = d
        }
        dndSettings.save()
    }

    // Close the nearest top-level row (an app group header, or a lone card)
    // at or above row `pos`. Closing a group header closes all of its
    // children too. Returns the row it closed, or -1 when there is none.
    // Working bottom to top keeps the rows above untouched.
    function closeTopLevelFrom(pos) {
        for (let i = Math.min(pos, list.count - 1); i >= 0; i--) {
            const idx = notifModel.index(i, 0)
            if (notifModel.data(idx, NotificationManager.Notifications.IsInGroupRole) !== true) {
                notifModel.close(idx)
                return i
            }
        }
        return -1
    }

    // ---- clear all ----
    // true while the "sweep away" animation plays; each card watches this flag
    property bool clearing: false
    readonly property int staggerStep: Math.round(Kirigami.Units.shortDuration * 0.4)
    readonly property int maxStaggered: 8   // only the first few rows get a delay

    function closeEverything() {
        let pos = list.count - 1
        while (pos >= 0) {
            const closed = closeTopLevelFrom(pos)
            if (closed < 0) {
                break
            }
            pos = closed - 1
        }
    }

    function clearAll() {
        if (clearing || list.count === 0) {
            return
        }
        if (!animationsEnabled) {
            closeEverything()
            return
        }
        clearPulse.restart()
        clearing = true
        // wait for the sweep to finish, then actually remove everything
        clearTimer.interval = Kirigami.Units.longDuration + maxStaggered * staggerStep + 40
        clearTimer.restart()
    }

    Timer {
        id: clearTimer
        onTriggered: {
            pane.closeEverything()
            clearResetTimer.restart()
        }
    }
    // give the model a moment to drop the rows, then let any survivors reappear
    Timer {
        id: clearResetTimer
        interval: 300
        onTriggered: pane.clearing = false
    }

    // bell wiggles whenever Do Not Disturb flips
    onDndActiveChanged: {
        if (animationsEnabled) {
            bellRing.restart()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: pane.classic ? 0 : Kirigami.Units.largeSpacing
        Layout.rightMargin: pane.classic ? 0 : Kirigami.Units.smallSpacing
        Layout.topMargin: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: pane.plasma ? 5 : 4
            font.weight: pane.plasma ? Font.Normal : Font.DemiBold
            text: "Notifications"
            Layout.fillWidth: true
        }

        PlasmaComponents.ToolButton {
            id: bellBtn
            icon.name: pane.dndActive ? "notifications-disabled" : "notifications"
            highlighted: pane.dndActive
            onClicked: pane.toggleDnd()

            SequentialAnimation {
                id: bellRing
                NumberAnimation { target: bellBtn; property: "rotation"; to: 16;  duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
                NumberAnimation { target: bellBtn; property: "rotation"; to: -12; duration: Kirigami.Units.shortDuration; easing.type: Easing.InOutQuad }
                NumberAnimation { target: bellBtn; property: "rotation"; to: 6;   duration: Kirigami.Units.shortDuration; easing.type: Easing.InOutQuad }
                NumberAnimation { target: bellBtn; property: "rotation"; to: 0;   duration: Kirigami.Units.shortDuration; easing.type: Easing.InQuad }
            }
        }

        PlasmaComponents.ToolButton {
            id: clearBtn
            icon.name: "edit-clear-all"
            enabled: list.count > 0 && !pane.clearing
            onClicked: pane.clearAll()

            // squash-and-bounce with a little twist when pressed
            SequentialAnimation {
                id: clearPulse
                ParallelAnimation {
                    NumberAnimation { target: clearBtn; property: "scale"; to: 0.6; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
                    NumberAnimation { target: clearBtn; property: "rotation"; to: -25; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
                }
                ParallelAnimation {
                    NumberAnimation { target: clearBtn; property: "scale"; to: 1.0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutBack; easing.overshoot: 3 }
                    NumberAnimation { target: clearBtn; property: "rotation"; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutBack; easing.overshoot: 3 }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: pane.classic ? 0 : Kirigami.Units.smallSpacing
            clip: true
            spacing: Kirigami.Units.smallSpacing
            model: notifModel

            // New cards slide in from the right and fade up
            add: Transition {
                enabled: pane.animationsEnabled
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration }
                    NumberAnimation { property: "x"; from: Kirigami.Units.gridUnit * 2; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                }
            }
            // Dismissed cards slide off to the right and fade out
            remove: Transition {
                enabled: pane.animationsEnabled && !pane.clearing
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: Kirigami.Units.longDuration }
                    NumberAnimation { property: "x"; to: list.width; duration: Kirigami.Units.longDuration; easing.type: Easing.InCubic }
                }
            }
            // Everything below glides up/down to fill the gap
            displaced: Transition {
                enabled: pane.animationsEnabled
                NumberAnimation { property: "y"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
            }

            delegate: Item {
                id: del
                width: ListView.view.width

                // "Clear all": every row slides right and fades, top rows first
                property real slide: 0
                transform: Translate { x: del.slide }
                states: State {
                    name: "clearing"
                    when: pane.clearing
                    PropertyChanges { target: del; opacity: 0; slide: del.width }
                }
                transitions: Transition {
                    to: "clearing"
                    SequentialAnimation {
                        PauseAnimation { duration: Math.min(index, pane.maxStaggered) * pane.staggerStep }
                        NumberAnimation { target: del; properties: "opacity,slide"; duration: Kirigami.Units.longDuration; easing.type: Easing.InCubic }
                    }
                }
                readonly property bool isGroup: model.isGroup === true
                readonly property bool inGroup: model.isInGroup === true
                height: isGroup
                    ? groupRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                    : card.height

                Connections {
                    target: pane
                    function onToggleGroupRequested(row) {
                        if (del.isGroup && row === index) {
                            model.isGroupExpanded = !model.isGroupExpanded
                        }
                    }
                }

                // ---- group header: one per app ----
                RowLayout {
                    id: groupRow
                    visible: del.isGroup
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Kirigami.Units.smallSpacing
                    }
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: model.applicationIconName
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: model.applicationName + "  ·  " + model.groupChildrenCount
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "window-close-symbolic"
                        opacity: 0.7
                        onClicked: notifModel.close(notifModel.index(index, 0))
                    }
                }

                // ---- a single notification card ----
                Rectangle {
                    id: card
                    visible: !del.isGroup
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: del.inGroup ? Kirigami.Units.largeSpacing : 0
                    height: cardColumn.implicitHeight + pane.cardPadding * 2
                    radius: pane.plasma ? 4 : 6
                    // Windows style: solid card. Plasma style: flat with a thin outline;
                    // hovering tints it with the accent color (like the calendar's today box).
                    color: !pane.plasma ? Kirigami.Theme.alternateBackgroundColor
                        : cardHover.hovered
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                    border.width: pane.plasma ? 1 : 0
                    border.color: cardHover.hovered
                        ? Kirigami.Theme.highlightColor
                        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                    HoverHandler { id: cardHover }

                    // Group info for the "+N notifications" button (only the
                    // last visible card of a group shows the button)
                    readonly property int headerRow: {
                        pane.rev; list.count
                        return del.inGroup ? pane.groupHeaderRow(index) : -1
                    }
                    readonly property bool isLastInGroup: {
                        pane.rev; list.count
                        return del.inGroup && pane.isLastInGroup(index)
                    }
                    readonly property int groupCount: {
                        pane.rev
                        return headerRow >= 0
                            ? pane.roleAt(headerRow, NotificationManager.Notifications.GroupChildrenCountRole)
                            : 0
                    }
                    readonly property bool groupExpanded: {
                        pane.rev
                        return headerRow >= 0
                            && pane.roleAt(headerRow, NotificationManager.Notifications.IsGroupExpandedRole) === true
                    }
                    readonly property int hiddenCount: Math.max(0, groupCount - notifModel.groupLimit)
                    readonly property bool showToggle: isLastInGroup && hiddenCount > 0

                    ColumnLayout {
                        id: cardColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: pane.cardPadding
                        }
                        spacing: pane.textSpacing

                        RowLayout {
                            id: row
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: pane.textSpacing

                                // Header: notification title (bold), with the time right under it
                                // (the app name already shows on the group header above)
                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: model.summary
                                    font.bold: true
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: Qt.formatTime(model.created, "h:mm AP")
                                    opacity: 0.6
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: model.body
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    opacity: 0.8
                                    visible: text.length > 0
                                }
                            }

                            PlasmaComponents.ToolButton {
                                icon.name: "window-close-symbolic"
                                opacity: 0.7
                                Layout.alignment: Qt.AlignTop
                                onClicked: notifModel.close(notifModel.index(index, 0))
                            }
                        }

                        // Bottom-left: "+N notifications" / "Show less"
                        PlasmaComponents.Button {
                            visible: card.showToggle
                            highlighted: !pane.plasma   // Windows style: solid accent-colored background
                            flat: pane.plasma           // Plasma style: plain flat button
                            Layout.alignment: Qt.AlignLeft
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            text: card.groupExpanded
                                ? "Show less"
                                : "+" + card.hiddenCount + (card.hiddenCount === 1 ? " notification" : " notifications")
                            onClicked: pane.toggleGroupRequested(card.headerRow)
                        }
                    }
                }
            }
        }

        PlasmaComponents.Label {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "No new notifications"
            opacity: 0.6
        }
    }
}
