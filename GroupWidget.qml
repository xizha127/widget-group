import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// A collapsible group: one toggle button on the bar that expands to reveal a row
// of real, live widgets (each a target plugin's pill + working popout). Members
// render inline in the bar window, so their popouts position below the bar
// correctly — the whole reason this works where a dropdown panel didn't.
PluginComponent {
    id: root

    property string variantId: ""
    property var variantData: null
    property var popoutService: null

    property bool expanded: false

    // When this group expands and "collapse others" is on, broadcast our id via a
    // shared (in-memory) global var; every other group instance collapses itself.
    onExpandedChanged: {
        if (root.expanded && root.collapseOthers && pluginService)
            pluginService.setGlobalVar(root.pluginId, "openGroup", root.variantId)
    }

    Connections {
        target: pluginService
        function onPluginDataChanged(changedId) {
            if (changedId !== root.pluginId || root.variantId === "") return
            const fresh = pluginService.getPluginVariantData(root.pluginId, root.variantId)
            if (fresh) root.variantData = fresh
        }
        function onGlobalVarChanged(changedId, varName) {
            if (changedId !== root.pluginId || varName !== "openGroup")
                return
            const opener = pluginService.getGlobalVar(root.pluginId, "openGroup", "")
            if (opener && opener !== root.variantId && root.expanded)
                root.expanded = false
        }
    }

    readonly property var targets: variantData?.targets ?? []
    readonly property string mainTarget: variantData?.mainTarget || ""
    readonly property string groupIcon: variantData?.icon || "widgets"
    readonly property string groupLabel: variantData?.label || ""
    readonly property string groupDisplay: variantData?.display || "both"
    readonly property string mainClickButton: variantData?.mainClickButton || "right"
    readonly property string expandIndicatorPosition: variantData?.expandIndicatorPosition || ""
    readonly property bool showArrow: variantData?.showArrow !== false
    readonly property bool showArrowOnlyOnHover: variantData?.showArrowOnlyOnHover === true
    readonly property bool hideMain: variantData?.hideMain === true
    readonly property bool collapseOthers: variantData?.collapseOthers === true

    property var _memberRefs: ({})

    readonly property bool showIcon:  groupDisplay !== "text"
    readonly property bool showLabel: groupDisplay !== "icon" && groupLabel !== ""
    readonly property bool hasToggleContent: showIcon || showLabel

    // Auto-orient expansion by the toggle's position on screen so members unfold
    // toward the open part of the bar: a group in the right half opens left (up
    // on a vertical bar), otherwise it opens right (down). Computed only while
    // collapsed — from the toggle, which is stable then — so there's no feedback
    // once members start growing. The chevrons, end-cap marker, and member layout
    // all derive from hLeft/vUp, so they stay consistent with the real direction.
    property bool _autoHLeft: false
    property bool _autoVUp: false
    readonly property bool hLeft: _autoHLeft
    readonly property bool vUp:   _autoVUp

    function _barExtent(vertical) {
        const win = root.blurBarWindow
        if (win) {
            const d = vertical ? win.height : win.width
            if (d > 0) return d
        }
        if (root.parentScreen) {
            const d = vertical ? root.parentScreen.height : root.parentScreen.width
            if (d > 0) return d
        }
        return 0
    }

    // Deadband around the centre: near the midpoint the toggle's position can sit
    // exactly on the boundary and jitter cx > w/2 back and forth, which flips
    // _autoHLeft and cancels the chevron's expand/collapse flip. Only commit a
    // change once the toggle is clearly past centre; keep the current value inside
    // the band.
    function _recomputeHDir(toggleItem) {
        if (root.expanded || !toggleItem) return
        const w = root._barExtent(false)
        if (w <= 0) return
        const cx = toggleItem.mapToItem(null, toggleItem.width / 2, 0).x
        const margin = w * 0.04
        if (cx > w / 2 + margin) root._autoHLeft = true
        else if (cx < w / 2 - margin) root._autoHLeft = false
    }

    function _recomputeVDir(toggleItem) {
        if (root.expanded || !toggleItem) return
        const h = root._barExtent(true)
        if (h <= 0) return
        const cy = toggleItem.mapToItem(null, 0, toggleItem.height / 2).y
        const margin = h * 0.04
        if (cy > h / 2 + margin) root._autoVUp = true
        else if (cy < h / 2 - margin) root._autoVUp = false
    }
    readonly property bool toggleArrowBeforeContent: {
        const pos = root._resolvedExpandIndicatorPosition()
        return pos === "left" || pos === "top"
    }

    // Auto-collapse behaviour
    readonly property bool autoCollapse: variantData?.autoCollapse === true
    readonly property int autoCollapseSeconds: {
        const s = variantData?.autoCollapseSeconds
        return (s && s >= 1) ? s : 5
    }
    readonly property bool autoCollapseOnLeave: variantData?.autoCollapseOnLeave === true
    property bool hovered: false

    function _barPosition() {
        const edge = root.axis?.edge || "top"
        return edge === "left" ? 2 : (edge === "right" ? 3 : (edge === "top" ? 0 : 1))
    }

    function _registerMember(targetId, member) {
        if (!targetId || !member)
            return
        const refs = Object.assign({}, root._memberRefs || {})
        refs[targetId] = member
        root._memberRefs = refs
    }

    function _unregisterMember(targetId, member) {
        if (!targetId || !member || !root._memberRefs || !root._memberRefs[targetId])
            return
        if (root._memberRefs[targetId] !== member)
            return
        const refs = Object.assign({}, root._memberRefs)
        delete refs[targetId]
        root._memberRefs = refs
    }

    function _mainMember() {
        return root.mainTarget ? (root._memberRefs?.[root.mainTarget] || null) : null
    }

    function _resolvedExpandIndicatorPosition() {
        if (root.expandIndicatorPosition)
            return root.expandIndicatorPosition
        const edge = root.axis?.edge || "top"
        return (edge === "left" || edge === "right") ? "bottom" : "right"
    }

    function _shouldShowArrow(hovered) {
        if (!root.hasToggleContent)
            return true
        if (!root.showArrow)
            return false
        if (root.showArrowOnlyOnHover)
            return hovered === true
        return true
    }

    function _toggleArrowSlotVisible() {
        return root.hasToggleContent ? root.showArrow : true
    }

    function _isMemberHidden(targetId) {
        return root.hideMain && !!root.mainTarget && targetId === root.mainTarget
    }

    function _isMemberVisible(targetId) {
        return !root._isMemberHidden(targetId)
    }

    function _horizontalToggleSourceComponent() {
        if (!root._toggleArrowSlotVisible())
            return hToggleBodyComp
        const pos = root._resolvedExpandIndicatorPosition()
        if (pos === "left")
            return hToggleRowBeforeComp
        if (pos === "top")
            return hToggleColumnBeforeComp
        if (pos === "bottom")
            return hToggleColumnAfterComp
        return hToggleRowAfterComp
    }

    function _verticalToggleSourceComponent() {
        if (!root._toggleArrowSlotVisible())
            return vToggleBodyComp
        const pos = root._resolvedExpandIndicatorPosition()
        if (pos === "left")
            return vToggleRowBeforeComp
        if (pos === "top")
            return vToggleColumnBeforeComp
        if (pos === "bottom")
            return vToggleColumnAfterComp
        return vToggleRowAfterComp
    }

    // The end caps mirror the toggle: group icon + collapse symbol, arranged by
    // the same expand/collapse-symbol position the user picks for the toggle.
    function _capSourceComponent() {
        const pos = root._resolvedExpandIndicatorPosition()
        if (pos === "left")   return capRowBeforeComp
        if (pos === "top")    return capColumnBeforeComp
        if (pos === "bottom") return capColumnAfterComp
        return capRowAfterComp   // "right"
    }

    Component {
        id: capRowAfterComp
        Row {
            spacing: Theme.spacingXS
            DankIcon { visible: root.showIcon; name: root.groupIcon; size: root.iconSize; color: Theme.surfaceText; anchors.verticalCenter: parent.verticalCenter }
            DankIcon { name: root._hChevron; rotation: 90; size: root.iconSize - 8; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Component {
        id: capRowBeforeComp
        Row {
            spacing: Theme.spacingXS
            DankIcon { name: root._hChevron; rotation: 90; size: root.iconSize - 8; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter }
            DankIcon { visible: root.showIcon; name: root.groupIcon; size: root.iconSize; color: Theme.surfaceText; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Component {
        id: capColumnAfterComp
        Column {
            spacing: 1
            DankIcon { visible: root.showIcon; name: root.groupIcon; size: root.iconSize; color: Theme.surfaceText; anchors.horizontalCenter: parent.horizontalCenter }
            DankIcon { name: root._vChevron; size: root.iconSize - 8; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }
    Component {
        id: capColumnBeforeComp
        Column {
            spacing: 1
            DankIcon { name: root._vChevron; size: root.iconSize - 8; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
            DankIcon { visible: root.showIcon; name: root.groupIcon; size: root.iconSize; color: Theme.surfaceText; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    function _handleGroupClick(button) {
        if (root.mainTarget) {
            const activateButton = root.mainClickButton === "left" ? Qt.LeftButton : Qt.RightButton
            if (button === activateButton && root._activateMainMember())
                return
        }
        root.expanded = !root.expanded
    }

    // Symmetric opposing-chevron icons that flip on expand/collapse only — there's
    // no left/right direction to compute, so this behaves identically in every
    // section (and sidesteps the centre-drift ambiguity entirely). The horizontal
    // toggle rotates the icon 90° so it reads as ‹ › / › ‹.
    readonly property string _hChevron: root.expanded ? "unfold_less" : "unfold_more"
    readonly property string _vChevron: root.expanded ? "unfold_less" : "unfold_more"

    function _activateMainMember() {
        const member = root._mainMember()
        if (!member || typeof member.triggerMainAction !== "function")
            return false
        return member.triggerMainAction()
    }

    Timer {
        id: collapseTimer
        interval: root.autoCollapseSeconds * 1000
        repeat: false
        // When "on leave" is set, only count down while the mouse is away from the
        // expanded group (re-entering resets it); otherwise count from expand.
        running: root.expanded && root.autoCollapse
                 && (root.autoCollapseOnLeave ? !root.hovered : true)
        onTriggered: root.expanded = false
    }

    Component {
        id: hToggleBodyComp
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                visible: root.showIcon
                name: root.groupIcon
                size: root.iconSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                visible: root.showLabel
                text: root.groupLabel
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component {
        id: hToggleArrowComp
        DankIcon {
            name: root._hChevron
            rotation: 90   // unfold icons are vertical; rotate so they read ‹ › / › ‹
            size: root.iconSize - 8
            color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component {
        id: hToggleRowBeforeComp
        Row {
            spacing: Theme.spacingXS
            readonly property int slotHeight: Math.max(root.iconSize, hBodyLoader.implicitHeight)
            Item {
                width: root.iconSize
                height: slotHeight
                Loader {
                    id: hArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
            Item {
                width: hBodyLoader.implicitWidth
                height: slotHeight
                Loader {
                    id: hBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleBodyComp
                }
            }
        }
    }

    Component {
        id: hToggleRowAfterComp
        Row {
            spacing: Theme.spacingXS
            readonly property int slotHeight: Math.max(root.iconSize, hBodyLoader.implicitHeight)
            Item {
                width: root.iconSize
                height: slotHeight
                Loader {
                    id: hArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
            Item {
                width: hBodyLoader.implicitWidth
                height: slotHeight
                Loader {
                    id: hBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleBodyComp
                }
            }
        }
    }

    Component {
        id: hToggleColumnBeforeComp
        Column {
            spacing: Theme.spacingXS
            readonly property int slotWidth: Math.max(root.iconSize, hBodyLoader.implicitWidth)
            Item {
                width: slotWidth
                height: root.iconSize
                Loader {
                    id: hArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
            Item {
                width: slotWidth
                height: hBodyLoader.implicitHeight
                Loader {
                    id: hBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleBodyComp
                }
            }
        }
    }

    Component {
        id: hToggleColumnAfterComp
        Column {
            spacing: Theme.spacingXS
            readonly property int slotWidth: Math.max(root.iconSize, hBodyLoader.implicitWidth)
            Item {
                width: slotWidth
                height: hBodyLoader.implicitHeight
                Loader {
                    id: hBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleBodyComp
                }
            }
            Item {
                width: slotWidth
                height: root.iconSize
                Loader {
                    id: hArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: hToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
        }
    }

    Component {
        id: vToggleBodyComp
        Column {
            spacing: 1
            DankIcon {
                visible: root.showIcon
                name: root.groupIcon
                size: root.iconSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                visible: root.showLabel
                text: root.groupLabel
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Component {
        id: vToggleArrowComp
        DankIcon {
            name: root._vChevron
            size: root.iconSize - 8
            color: Theme.surfaceVariantText
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Component {
        id: vToggleRowBeforeComp
        Row {
            spacing: Theme.spacingXS
            readonly property int slotHeight: Math.max(root.iconSize, vBodyLoader.implicitHeight)
            Item {
                width: root.iconSize
                height: slotHeight
                Loader {
                    id: vArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
            Item {
                width: vBodyLoader.implicitWidth
                height: slotHeight
                Loader {
                    id: vBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleBodyComp
                }
            }
        }
    }

    Component {
        id: vToggleRowAfterComp
        Row {
            spacing: Theme.spacingXS
            readonly property int slotHeight: Math.max(root.iconSize, vBodyLoader.implicitHeight)
            Item {
                width: root.iconSize
                height: slotHeight
                Loader {
                    id: vArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
            Item {
                width: vBodyLoader.implicitWidth
                height: slotHeight
                Loader {
                    id: vBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleBodyComp
                }
            }
        }
    }

    Component {
        id: vToggleColumnBeforeComp
        Column {
            spacing: Theme.spacingXS
            readonly property int slotWidth: Math.max(root.iconSize, vBodyLoader.implicitWidth)
            Item {
                width: slotWidth
                height: root.iconSize
                Loader {
                    id: vArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
            Item {
                width: slotWidth
                height: vBodyLoader.implicitHeight
                Loader {
                    id: vBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleBodyComp
                }
            }
        }
    }

    Component {
        id: vToggleColumnAfterComp
        Column {
            spacing: Theme.spacingXS
            readonly property int slotWidth: Math.max(root.iconSize, vBodyLoader.implicitWidth)
            Item {
                width: slotWidth
                height: vBodyLoader.implicitHeight
                Loader {
                    id: vBodyLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleBodyComp
                }
            }
            Item {
                width: slotWidth
                height: root.iconSize
                Loader {
                    id: vArrowLoader
                    anchors.centerIn: parent
                    sourceComponent: vToggleArrowComp
                    visible: root._shouldShowArrow(root.hovered)
                }
            }
        }
    }

    // ── Horizontal bar pill ──────────────────────────────────────────────────
    horizontalBarPill: Component {
        Item {
            implicitWidth: hRow.width
            implicitHeight: hRow.height

            // Solid backing shown while expanded so the group stays readable when
            // its members overlap an adjacent bar section (the bar itself may be
            // transparent, making overlapping icons blend together otherwise).
            Rectangle {
                anchors.fill: hRow
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
            }

            Row {
                id: hRow
                spacing: Theme.spacingXS
                layoutDirection: root.hLeft ? Qt.RightToLeft : Qt.LeftToRight

                HoverHandler { onHoveredChanged: { root.hovered = hovered; if (hovered) root._recomputeHDir(hToggle) } }

            // Recompute the unfold direction once the bar has settled.
            Timer { interval: 150; running: true; repeat: false; onTriggered: root._recomputeHDir(hToggle) }

            // Toggle button
            Rectangle {
                id: hToggle
                width: hToggleLoader.implicitWidth + Theme.spacingS * 2
                height: hToggleLoader.implicitHeight + Theme.spacingXS * 2
                radius: Theme.cornerRadius
                color: hToggleArea.containsMouse ? Theme.primaryHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Loader {
                    id: hToggleLoader
                    anchors.centerIn: parent
                    sourceComponent: root._horizontalToggleSourceComponent()
                }

                MouseArea {
                    id: hToggleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        root._handleGroupClick(mouse.button)
                    }
                }
            }

            Repeater {
                model: root.targets

                delegate: Item {
                    id: hWrap
                    required property var modelData
                    visible: root._isMemberVisible(hWrap.modelData)
                    height: root._isMemberVisible(hWrap.modelData) && root.expanded ? hMember.implicitHeight : 0
                    width: root._isMemberVisible(hWrap.modelData) && root.expanded ? hMember.implicitWidth : 0
                    clip: true
                    opacity: root._isMemberVisible(hWrap.modelData) && root.expanded ? 1 : 0
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on width   { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }

                    GroupMember {
                        id: hMember
                        anchors.verticalCenter: parent.verticalCenter
                        targetId: hWrap.modelData
                        pluginService: root.pluginService
                        popoutService: root.popoutService
                        axis: root.axis
                        section: root.section
                        parentScreen: root.parentScreen
                        widgetThickness: root.widgetThickness
                        barThickness: root.barThickness
                        barSpacing: root.barSpacing
                        barConfig: root.barConfig
                        blurBarWindow: root.blurBarWindow
                        onReadyChanged: {
                            if (ready)
                                root._registerMember(hWrap.modelData, hMember)
                        }
                    }

                    Component.onCompleted: root._registerMember(hWrap.modelData, hMember)
                    Component.onDestruction: root._unregisterMember(hWrap.modelData, hMember)
                }
            }

            // Group end cap — a matching button at the far end (group icon + the
            // collapse chevron), so there's a collapse control with a clear hover
            // target at both ends of the expanded panel.
            Rectangle {
                id: hCap
                visible: root.targets.length > 0 && root.targets.some(t => root._isMemberVisible(t))
                width: root.expanded ? hCapLoader.implicitWidth + Theme.spacingS * 2 : 0
                height: hCapLoader.implicitHeight + Theme.spacingXS * 2
                radius: Theme.cornerRadius
                color: hCapArea.containsMouse ? Theme.primaryHover : "transparent"
                opacity: root.expanded ? 1 : 0
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                Behavior on width   { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
                Behavior on color   { ColorAnimation { duration: Theme.shortDuration } }

                Loader {
                    id: hCapLoader
                    anchors.centerIn: parent
                    sourceComponent: root._capSourceComponent()
                }

                MouseArea {
                    id: hCapArea
                    anchors.fill: parent
                    enabled: root.expanded
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = false
                }
            }
        }
        }
    }

    // ── Vertical bar pill ────────────────────────────────────────────────────
    // Members render above the toggle when "up", below it when "down".
    Component {
        id: vMembersComp
        Column {
            spacing: Theme.spacingXS

            // End cap at the top — far end when expanding upward
            Rectangle {
                id: vCapTop
                visible: root.targets.length > 0 && root.targets.some(t => root._isMemberVisible(t)) && root.vUp
                anchors.horizontalCenter: parent.horizontalCenter
                width: vCapTopLoader.implicitWidth + Theme.spacingXS * 2
                height: root.expanded ? vCapTopLoader.implicitHeight + Theme.spacingXS * 2 : 0
                radius: Theme.cornerRadius
                color: vCapTopArea.containsMouse ? Theme.primaryHover : "transparent"
                opacity: root.expanded ? 1 : 0
                clip: true
                Behavior on height  { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
                Behavior on color   { ColorAnimation { duration: Theme.shortDuration } }

                Loader {
                    id: vCapTopLoader
                    anchors.centerIn: parent
                    sourceComponent: root._capSourceComponent()
                }

                MouseArea {
                    id: vCapTopArea
                    anchors.fill: parent
                    enabled: root.expanded
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = false
                }
            }

            Repeater {
                model: root.targets
                delegate: Item {
                    id: vWrap
                    required property var modelData
                    visible: root._isMemberVisible(vWrap.modelData)
                    width: root._isMemberVisible(vWrap.modelData) && root.expanded ? vMember.implicitWidth : 0
                    height: root._isMemberVisible(vWrap.modelData) && root.expanded ? vMember.implicitHeight : 0
                    clip: true
                    opacity: root._isMemberVisible(vWrap.modelData) && root.expanded ? 1 : 0
                    anchors.horizontalCenter: parent.horizontalCenter

                    Behavior on height  { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }

                    GroupMember {
                        id: vMember
                        anchors.horizontalCenter: parent.horizontalCenter
                        targetId: vWrap.modelData
                        pluginService: root.pluginService
                        popoutService: root.popoutService
                        axis: root.axis
                        section: root.section
                        parentScreen: root.parentScreen
                        widgetThickness: root.widgetThickness
                        barThickness: root.barThickness
                        barSpacing: root.barSpacing
                        barConfig: root.barConfig
                        blurBarWindow: root.blurBarWindow
                    }
                }
            }

            // End cap at the bottom — far end when expanding downward
            Rectangle {
                id: vCapBot
                visible: root.targets.length > 0 && root.targets.some(t => root._isMemberVisible(t)) && !root.vUp
                anchors.horizontalCenter: parent.horizontalCenter
                width: vCapBotLoader.implicitWidth + Theme.spacingXS * 2
                height: root.expanded ? vCapBotLoader.implicitHeight + Theme.spacingXS * 2 : 0
                radius: Theme.cornerRadius
                color: vCapBotArea.containsMouse ? Theme.primaryHover : "transparent"
                opacity: root.expanded ? 1 : 0
                clip: true
                Behavior on height  { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
                Behavior on color   { ColorAnimation { duration: Theme.shortDuration } }

                Loader {
                    id: vCapBotLoader
                    anchors.centerIn: parent
                    sourceComponent: root._capSourceComponent()
                }

                MouseArea {
                    id: vCapBotArea
                    anchors.fill: parent
                    enabled: root.expanded
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = false
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: vCol.width
            implicitHeight: vCol.height

            // Solid backing shown while expanded so the group stays readable when
            // its members overlap an adjacent bar section.
            Rectangle {
                anchors.fill: vCol
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
            }

            Column {
                id: vCol
                spacing: Theme.spacingXS

                HoverHandler { onHoveredChanged: { root.hovered = hovered; if (hovered) root._recomputeVDir(vToggle) } }

                // Recompute the unfold direction once the bar has settled.
                Timer { interval: 150; running: true; repeat: false; onTriggered: root._recomputeVDir(vToggle) }

            // Members above the toggle (when expanding up)
            Loader {
                active: root.vUp
                sourceComponent: vMembersComp
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                id: vToggle
                width: vToggleLoader.implicitWidth + Theme.spacingXS * 2
                height: vToggleLoader.implicitHeight + Theme.spacingS * 2
                radius: Theme.cornerRadius
                color: vToggleArea.containsMouse ? Theme.primaryHover : "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                Loader {
                    id: vToggleLoader
                    anchors.centerIn: parent
                    sourceComponent: root._verticalToggleSourceComponent()
                }

                MouseArea {
                    id: vToggleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        root._handleGroupClick(mouse.button)
                    }
                }
            }

            // Members below the toggle (when expanding down)
            Loader {
                active: !root.vUp
                sourceComponent: vMembersComp
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        }
    }
}
