import QtQuick
import org.kde.plasma.core as PlasmaCore

// Root is an Item on purpose: Loader can't load a bare window.
Item {
    id: wrapper
    property Item anchorItem
    property var panelLocation
    property date now: new Date()
    property alias open: dlg.visible
    property double lastClosed: 0

    PlasmaCore.Dialog {
        id: dlg
        visualParent: wrapper.anchorItem
        location: wrapper.panelLocation
        type: PlasmaCore.Dialog.AppletPopup
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Types.NoBackground
        onVisibleChanged: if (!visible) wrapper.lastClosed = Date.now()

        mainItem: Cards { now: wrapper.now }
    }
}
