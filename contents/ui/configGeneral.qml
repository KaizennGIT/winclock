import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    // Plasma fills these in from main.xml (cfg_<entry name>)
    property string cfg_timeFormat
    property string cfg_timeFormatDefault
    property string cfg_dateFormat
    property string cfg_dateFormatDefault
    property bool cfg_showDate
    property bool cfg_showDateDefault
    property bool cfg_flyout24h
    property bool cfg_flyout24hDefault
    property bool cfg_flyoutSeconds
    property bool cfg_flyoutSecondsDefault
    property bool cfg_floating
    property bool cfg_floatingDefault
    property bool cfg_notifAnimations
    property bool cfg_notifAnimationsDefault
    property int cfg_flyoutWidth
    property int cfg_flyoutWidthDefault

    readonly property var timePresets: [
        { text: "12-hour  (3:45 PM)",           fmt: "h:mm AP" },
        { text: "12-hour with seconds  (3:45:09 PM)", fmt: "h:mm:ss AP" },
        { text: "24-hour  (15:45)",             fmt: "HH:mm" },
        { text: "24-hour with seconds  (15:45:09)", fmt: "HH:mm:ss" }
    ]
    readonly property var datePresets: [
        { text: "11/5/2026",       fmt: "M/d/yyyy" },
        { text: "5/11/2026",       fmt: "d/M/yyyy" },
        { text: "2026-11-05",      fmt: "yyyy-MM-dd" },
        { text: "Nov 5, 2026",     fmt: "MMM d, yyyy" },
        { text: "Thu 5 Nov",       fmt: "ddd d MMM" }
    ]

    // which preset matches the current format; the last entry is "Custom"
    function presetIndex(presets, fmt) {
        for (let i = 0; i < presets.length; i++) {
            if (presets[i].fmt === fmt) {
                return i
            }
        }
        return presets.length
    }

    Kirigami.FormLayout {

        // ---------------- panel clock ----------------
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Panel clock"
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: "Time:"
            model: page.timePresets.map(p => p.text).concat(["Custom"])
            currentIndex: page.presetIndex(page.timePresets, page.cfg_timeFormat)
            onActivated: index => {
                if (index < page.timePresets.length) {
                    page.cfg_timeFormat = page.timePresets[index].fmt
                }
            }
        }
        QQC2.TextField {
            Kirigami.FormData.label: "Time format:"
            Layout.minimumWidth: Kirigami.Units.gridUnit * 14
            text: page.cfg_timeFormat
            onTextEdited: page.cfg_timeFormat = text
        }
        QQC2.Label {
            Kirigami.FormData.label: "Preview:"
            text: Qt.formatTime(new Date(), page.cfg_timeFormat)
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.Wrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: "Write your own format in the box above. h / hh = hour (12-hour), H / HH = hour (24-hour), m / mm = minute, s / ss = second, AP = AM/PM, ap = am/pm. Put your own text in single quotes, like 'Time:' h:mm."
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: "Date:"
            text: "Show the date"
            checked: page.cfg_showDate
            onToggled: page.cfg_showDate = checked
        }
        QQC2.ComboBox {
            enabled: page.cfg_showDate
            Kirigami.FormData.label: "Date style:"
            model: page.datePresets.map(p => p.text).concat(["Custom"])
            currentIndex: page.presetIndex(page.datePresets, page.cfg_dateFormat)
            onActivated: index => {
                if (index < page.datePresets.length) {
                    page.cfg_dateFormat = page.datePresets[index].fmt
                }
            }
        }
        QQC2.TextField {
            enabled: page.cfg_showDate
            Kirigami.FormData.label: "Date format:"
            Layout.minimumWidth: Kirigami.Units.gridUnit * 14
            text: page.cfg_dateFormat
            onTextEdited: page.cfg_dateFormat = text
        }
        QQC2.Label {
            Kirigami.FormData.label: "Preview:"
            enabled: page.cfg_showDate
            text: Qt.formatDate(new Date(), page.cfg_dateFormat)
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.Wrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: "d / dd = day, ddd / dddd = weekday name, M / MM = month number, MMM / MMMM = month name, yy / yyyy = year."
        }

        // ---------------- flyout ----------------
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Flyout"
        }

        QQC2.CheckBox {
            text: "Use 24-hour time in the flyout"
            checked: page.cfg_flyout24h
            onToggled: page.cfg_flyout24h = checked
        }
        QQC2.CheckBox {
            text: "Show seconds in the flyout"
            checked: page.cfg_flyoutSeconds
            onToggled: page.cfg_flyoutSeconds = checked
        }
        QQC2.SpinBox {
            id: widthSpin
            Kirigami.FormData.label: "Flyout width:"
            from: 20
            to: 60
            onValueModified: page.cfg_flyoutWidth = value
        }
        // This keeps the box in sync even after you have used it, so
        // "Reset all to defaults" always moves it.
        Binding {
            target: widthSpin
            property: "value"
            value: page.cfg_flyoutWidth
        }
        QQC2.Label {
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: "One unit is about 18 pixels at normal scaling."
        }
        QQC2.CheckBox {
            text: "Animate notifications"
            checked: page.cfg_notifAnimations
            onToggled: page.cfg_notifAnimations = checked
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.Wrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: "Slide and fade effects when notifications arrive, are dismissed or cleared, and when Do Not Disturb changes."
        }
        QQC2.CheckBox {
            text: "Floating flyout (no frame)"
            checked: page.cfg_floating
            onToggled: page.cfg_floating = checked
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.Wrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: "Turn off floating to use Plasma's normal framed popup instead."
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }
        QQC2.Button {
            text: "Reset all to defaults"
            icon.name: "edit-undo"
            onClicked: {
                // keep these in sync with contents/config/main.xml
                page.cfg_timeFormat = "h:mm AP"
                page.cfg_dateFormat = "M/d/yyyy"
                page.cfg_showDate = true
                page.cfg_flyout24h = false
                page.cfg_flyoutSeconds = true
                page.cfg_floating = true
                page.cfg_notifAnimations = true
                page.cfg_flyoutWidth = 24
            }
        }
        QQC2.Label {
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: "Press Apply afterwards to save."
        }
    }
}
