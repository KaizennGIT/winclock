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
                        visible: model.groupChildrenCount > notifModel.groupLimit
                        icon.name: model.isGroupExpanded ? "go-up-symbolic" : "go-down-symbolic"
                        onClicked: model.isGroupExpanded = !model.isGroupExpanded
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
                    height: row.implicitHeight + Kirigami.Units.smallSpacing * 2
                    radius: 6
                    color: Kirigami.Theme.alternateBackgroundColor

                    RowLayout {
                        id: row
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
                            Layout.alignment: Qt.AlignTop
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: model.summary
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: model.body
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: model.applicationName + "  ·  " + Qt.formatTime(model.created, "h:mm AP")
                                opacity: 0.6
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                        }

                        PlasmaComponents.ToolButton {
                            icon.name: "window-close-symbolic"
                            opacity: 0.7
                            Layout.alignment: Qt.AlignTop
                            onClicked: notifModel.close(notifModel.index(index, 0))
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
