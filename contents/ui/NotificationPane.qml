import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

ColumnLayout {
    id: pane
    spacing: Kirigami.Units.smallSpacing

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

    // Close every top-level row, bottom to top. Closing a group header closes
    // all of its children, so children are skipped.
    function clearAll() {
        for (let i = list.count - 1; i >= 0; i--) {
            const idx = notifModel.index(i, 0)
            if (notifModel.data(idx, NotificationManager.Notifications.IsInGroupRole) === true) {
                continue
            }
            notifModel.close(idx)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        Layout.topMargin: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: 4
            text: "Notifications"
            Layout.fillWidth: true
        }

        PlasmaComponents.ToolButton {
            icon.name: pane.dndActive ? "notifications-disabled" : "notifications"
            highlighted: pane.dndActive
            onClicked: pane.toggleDnd()
        }

        PlasmaComponents.ToolButton {
            icon.name: "edit-clear-all"
            enabled: list.count > 0
            onClicked: pane.clearAll()
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            clip: true
            spacing: Kirigami.Units.smallSpacing
            model: notifModel

            delegate: Item {
                id: del
                width: ListView.view.width
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
                    radius: 6
                    color: Kirigami.Theme.alternateBackgroundColor

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
                            highlighted: true   // solid accent-colored background
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
