import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// Root is an Item on purpose: Loader can't load a bare window.
Item {
    id: wrapper
    property Item anchorItem
    property var panelLocation
    property var prefs          // set by main.qml: gives access to the settings
    property date now: new Date()
    property alias open: dlg.visible
    property double lastClosed: 0

    // distance between the cards and the panel. Make it bigger for more space.
    readonly property int edgeGap: Math.round(Kirigami.Units.gridUnit / 2)

    PlasmaCore.Dialog {
        id: dlg
        visualParent: wrapper.anchorItem
        location: wrapper.panelLocation
        type: PlasmaCore.Dialog.AppletPopup
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Types.NoBackground
        onVisibleChanged: if (!visible) wrapper.lastClosed = Date.now()

        mainItem: Cards {
            now: wrapper.now
            prefs: wrapper.prefs
            gapBottom: wrapper.panelLocation === PlasmaCore.Types.BottomEdge ? wrapper.edgeGap : 0
            gapTop: wrapper.panelLocation === PlasmaCore.Types.TopEdge ? wrapper.edgeGap : 0
            gapLeft: wrapper.panelLocation === PlasmaCore.Types.LeftEdge ? wrapper.edgeGap : 0
            gapRight: wrapper.panelLocation === PlasmaCore.Types.RightEdge ? wrapper.edgeGap : 0
        }
    }
}
