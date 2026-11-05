import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

ColumnLayout {
    spacing: Kirigami.Units.smallSpacing

    NotificationManager.Notifications {
        id: notifModel
        showExpired: true
        showDismissed: true
        showJobs: false
        urgencies: NotificationManager.Notifications.CriticalUrgency
                 | NotificationManager.Notifications.NormalUrgency
                 | NotificationManager.Notifications.LowUrgency
    }

    Kirigami.Heading {
        level: 4
        text: "Notifications"
        Layout.leftMargin: Kirigami.Units.largeSpacing
        Layout.topMargin: Kirigami.Units.smallSpacing
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

            delegate: Rectangle {
                width: ListView.view.width
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
                        icon.name: "window-close"
                        Layout.alignment: Qt.AlignTop
                        onClicked: notifModel.close(notifModel.index(index, 0))
                    }
                }
            }
        }

        PlasmaComponents.Label {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "No notifications"
            opacity: 0.6
        }
    }
}
