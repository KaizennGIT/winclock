import QtQuick
import org.kde.plasma.workspace.calendar as PlasmaCalendar

Item {
    property date now: new Date()

    PlasmaCalendar.MonthView {
        anchors.fill: parent
        today: parent.now
    }
}
