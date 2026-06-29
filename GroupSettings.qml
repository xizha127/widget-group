import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "widgetGroup"

    property string newGroupName: ""
    property string newGroupIcon: "widgets"

    property string editingGroupId: ""
    property var editingGroup: null
    property string newMemberId: ""
    property int editingMemberIndex: -1
    property string editDisplay: "both"      // both | icon | text
    property bool editAutoCollapse: false
    property int editAutoCollapseSeconds: 5
    property bool editAutoCollapseOnLeave: false
    property string editMainTarget: ""
    property string editMainClickButton: "right"
    property string editMainMarkerColor: "primary"
    property string editExpandIndicatorPosition: ""
    property bool editShowArrow: true
    property bool editShowArrowOnlyOnHover: false
    property bool editHideMain: false
    property bool editCollapseOthers: false
    property bool editOverlayExpand: false
    property bool editShowExpandedBorder: true

    onVariantsChanged: {
        localGroups.clear()
        for (let i = 0; i < variants.length; i++) {
            const v = variants[i]
            localGroups.append({
                vid: v.id || "",
                vname: v.name || "",
                vicon: v.icon || "widgets",
                vcount: (v.targets ? v.targets.length : 0)
            })
        }
        if (editingGroupId !== "") {
            editingGroup = variants.find(v => v.id === editingGroupId) || null
            editMainTarget = editingGroup?.mainTarget || ""
            editMainClickButton = editingGroup?.mainClickButton || "right"
            editMainMarkerColor = editingGroup?.mainMarkerColor || "primary"
            editExpandIndicatorPosition = editingGroup?.expandIndicatorPosition || ""
            editShowArrow = editingGroup?.showArrow !== false
            editShowArrowOnlyOnHover = editingGroup?.showArrowOnlyOnHover === true
            editHideMain = editingGroup?.hideMain === true
            editCollapseOthers = editingGroup?.collapseOthers === true
            editOverlayExpand = editingGroup?.overlayExpand === true
            editShowExpandedBorder = editingGroup?.showExpandedBorder !== false
            _syncMembers()
        }
    }

    ListModel { id: localGroups }
    ListModel { id: localMembers }

    function _syncMembers() {
        localMembers.clear()
        const t = editingGroup?.targets ?? []
        for (let i = 0; i < t.length; i++)
            localMembers.append({ mid: t[i] })
    }

    function _currentMembers() {
        const out = []
        for (let i = 0; i < localMembers.count; i++)
            out.push(localMembers.get(i).mid)
        return out
    }

    function _editMember(index) {
        const r = localMembers.get(index)
        if (!r) return
        editingMemberIndex = index
        newMemberId = r.mid
        memberPicker.currentValue = _nameFor(r.mid)
    }

    function _cancelMemberEdit() {
        editingMemberIndex = -1
        newMemberId = ""
        memberPicker.currentValue = ""
    }

    function _saveMembers(arr) {
        if (!editingGroupId || !pluginService) return
        const mainTarget = arr.includes(editMainTarget) ? editMainTarget : ""
        editMainTarget = mainTarget
        updateVariant(editingGroupId, { targets: arr, mainTarget })
        editingGroup = Object.assign({}, editingGroup, { targets: arr, mainTarget })
        _syncMembers()
        for (let i = 0; i < localGroups.count; i++) {
            if (localGroups.get(i).vid === editingGroupId) {
                localGroups.setProperty(i, "vcount", arr.length)
                break
            }
        }
    }

    function _selectGroup(v) {
        editingGroupId = v.id
        editingGroup = v
        editNameField.text = v.name || ""
        editLabelField.text = v.label || ""
        editIconField.currentIcon = v.icon || "widgets"
        editDisplay = v.display || "both"
        editAutoCollapse = v.autoCollapse === true
        editAutoCollapseSeconds = (v.autoCollapseSeconds && v.autoCollapseSeconds >= 1) ? v.autoCollapseSeconds : 5
        editAutoCollapseOnLeave = v.autoCollapseOnLeave === true
        editMainTarget = v.mainTarget || ""
        editMainClickButton = v.mainClickButton || "right"
        editMainMarkerColor = v.mainMarkerColor || "primary"
        editExpandIndicatorPosition = v.expandIndicatorPosition || ""
        editShowArrow = v.showArrow !== false
        editShowArrowOnlyOnHover = v.showArrowOnlyOnHover === true
        editHideMain = v.hideMain === true
        editCollapseOthers = v.collapseOthers === true
        editOverlayExpand = v.overlayExpand === true
        editShowExpandedBorder = v.showExpandedBorder !== false
        newMemberId = ""
        editingMemberIndex = -1
        memberPicker.currentValue = ""
        _syncMembers()
    }

    function _saveGroupMeta() {
        if (!editingGroupId || !pluginService) return
        const nm = editNameField.text.trim()
        if (!nm) return
        const cfg = {
            name: nm,
            label: editLabelField.text.trim(),
            icon: editIconField.currentIcon || "widgets",
            display: editDisplay,
            autoCollapse: editAutoCollapse,
            autoCollapseSeconds: editAutoCollapseSeconds,
            autoCollapseOnLeave: editAutoCollapseOnLeave,
            mainTarget: editMainTarget || "",
            mainClickButton: editMainClickButton || "right",
            mainMarkerColor: editMainMarkerColor || "primary",
            expandIndicatorPosition: editExpandIndicatorPosition || "",
            showArrow: editShowArrow !== false,
            showArrowOnlyOnHover: editShowArrow ? editShowArrowOnlyOnHover === true : false,
            hideMain: editHideMain === true,
            collapseOthers: editCollapseOthers === true,
            overlayExpand: editOverlayExpand === true,
            showExpandedBorder: editShowExpandedBorder === true
        }
        updateVariant(editingGroupId, cfg)
        editingGroup = Object.assign({}, editingGroup, cfg)
        for (let i = 0; i < localGroups.count; i++) {
            if (localGroups.get(i).vid === editingGroupId) {
                localGroups.setProperty(i, "vname", nm)
                localGroups.setProperty(i, "vicon", cfg.icon)
                break
            }
        }
    }

    function _saveDisplay(v) { editDisplay = v; _saveGroupMeta() }
    function _saveAutoCollapse(v) { editAutoCollapse = v; _saveGroupMeta() }
    function _saveAutoCollapseOnLeave(v) { editAutoCollapseOnLeave = v; _saveGroupMeta() }
    function _saveAutoCollapseSeconds(v) { editAutoCollapseSeconds = v; _saveGroupMeta() }
    function _saveMainClickButton(v) { editMainClickButton = v; _saveGroupMeta() }
    function _saveMainMarkerColor(v) { editMainMarkerColor = v; _saveGroupMeta() }
    function _saveExpandIndicatorPosition(v) { editExpandIndicatorPosition = v; _saveGroupMeta() }
    function _saveShowArrow(v) {
        editShowArrow = v
        if (!v)
            editShowArrowOnlyOnHover = false
        _saveGroupMeta()
    }
    function _saveShowArrowOnlyOnHover(v) { editShowArrowOnlyOnHover = v; _saveGroupMeta() }
    function _saveHideMain(v) { editHideMain = v; _saveGroupMeta() }
    function _saveCollapseOthers(v) { editCollapseOthers = v; _saveGroupMeta() }
    function _saveOverlayExpand(v) { editOverlayExpand = v; _saveGroupMeta() }
    function _saveShowExpandedBorder(v) { editShowExpandedBorder = v; _saveGroupMeta() }
    function _toggleMainTarget(id) {
        editMainTarget = editMainTarget === id ? "" : id
        _saveGroupMeta()
    }

    function _markerPreviewColor(mode) {
        if (mode === "secondary") return Theme.secondary
        if (mode === "tertiary") return Theme.tertiary
        if (mode === "surface") return Theme.surfaceContainerHighest
        return Theme.primary
    }

    function _markerPreviewTextColor(mode) {
        if (mode === "surface") return Theme.surfaceText
        const c = root._markerPreviewColor(mode)
        return c.hslLightness > 0.6 ? "#000000" : "#ffffff"
    }

    // DMS's built-in bar widgets (media controls, power menu, system tray, etc.)
    // are not PluginService plugins, so they do not appear in availablePluginsList.
    // Mirror the core widget catalog from DMS WidgetsTab so Widget Group can select
    // both core DMS widgets and third-party/system plugin widgets.
    readonly property var coreWidgetTargets: [
        { id: "workspaceSwitcher", name: "Workspace Switcher", icon: "view_module" },
        { id: "focusedWindow", name: "Focused Window", icon: "window" },
        { id: "runningApps", name: "Running Apps", icon: "apps" },
        { id: "appsDock", name: "Apps Dock", icon: "dock_to_bottom" },
        { id: "clock", name: "Clock", icon: "schedule" },
        { id: "weather", name: "Weather Widget", icon: "wb_sunny" },
        { id: "music", name: "Media Controls", icon: "music_note" },
        { id: "clipboard", name: "Clipboard Manager", icon: "content_paste" },
        { id: "cpuUsage", name: "CPU Usage", icon: "memory" },
        { id: "memUsage", name: "Memory Usage", icon: "developer_board" },
        { id: "diskUsage", name: "Disk Usage", icon: "storage" },
        { id: "cpuTemp", name: "CPU Temperature", icon: "device_thermostat" },
        { id: "gpuTemp", name: "GPU Temperature", icon: "auto_awesome_mosaic" },
        { id: "systemTray", name: "System Tray", icon: "notifications" },
        { id: "privacyIndicator", name: "Privacy Indicator", icon: "privacy_tip" },
        { id: "layout", name: "Layout", icon: "view_quilt" },
        { id: "controlCenterButton", name: "Control Center", icon: "settings" },
        { id: "notificationButton", name: "Notification Center", icon: "notifications" },
        { id: "battery", name: "Battery", icon: "battery_std" },
        { id: "vpn", name: "VPN", icon: "vpn_lock" },
        { id: "idleInhibitor", name: "Idle Inhibitor", icon: "motion_sensor_active" },
        { id: "capsLockIndicator", name: "Caps Lock Indicator", icon: "shift_lock" },
        { id: "spacer", name: "Spacer", icon: "more_horiz" },
        { id: "separator", name: "Separator", icon: "remove" },
        { id: "network_speed_monitor", name: "Network Speed Monitor", icon: "network_check" },
        { id: "keyboard_layout_name", name: "Keyboard Layout Name", icon: "keyboard" },
        { id: "notepadButton", name: "Notepad", icon: "assignment" },
        { id: "colorPicker", name: "Color Picker", icon: "palette" },
        { id: "systemUpdate", name: "System Update", icon: "update" },
        { id: "powerMenuButton", name: "Power", icon: "power_settings_new" }
    ]

    readonly property var availableTargets: {
        const targets = coreWidgetTargets.slice()
        if (!pluginService) return targets
        return targets.concat(pluginService.availablePluginsList
            .filter(p => p.id !== "widgetGroup"
                      && (p.type === "widget" || (pluginService.pluginWidgetComponents && pluginService.pluginWidgetComponents[p.id])))
            .map(p => ({ id: p.id, name: p.name, icon: p.icon || "extension" })))
            .sort((a, b) => String(a.name || "").localeCompare(String(b.name || ""), undefined, { sensitivity: "base" }))
    }
    readonly property var availableTargetNames: availableTargets.map(p => p.name)

    function _targetFor(id) {
        return availableTargets.find(p => p.id === id) || null
    }

    function _nameFor(id) {
        const t = _targetFor(id)
        return t ? t.name : id
    }

    function _iconFor(id) {
        const t = _targetFor(id)
        return t ? (t.icon || "extension") : "extension"
    }

    function _isCoreTarget(id) {
        return coreWidgetTargets.some(p => p.id === id)
    }

    function _isTargetAvailable(id) {
        return _isCoreTarget(id) || !!(pluginService && pluginService.availablePlugins[id]?.loaded)
    }

    // ── Header ─────────────────────────────────────────────────────────────────
    StyledText {
        width: parent.width
        text: "Widget Groups"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "One bar button that expands to reveal several widgets inline — each keeps its own live pill and popout."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    // Usage hint
    StyledRect {
        width: parent.width
        height: hintColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surface

        Column {
            id: hintColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingS

            Row {
                spacing: Theme.spacingS
                DankIcon { name: "info"; size: Theme.iconSize; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                StyledText {
                    text: "How to use"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                width: parent.width
                text: "1. Enable the widget plugins you want to group\n2. Create a group above, then click it to edit (click again to collapse)\n3. Set the button icon, label, and what it shows (icon/text/both)\n4. Choose which click should activate the selected main widget, plus the marker color\n5. Optionally pick where the expand/collapse symbol appears relative to the button\n6. Optionally set Auto-collapse to fold the group again after a delay\n7. Add member widgets; click a member to change its plugin, use the arrows to reorder, or ✕ to remove\n8. Go to Bar Settings → Add Widget to place the group on your bar\n\nMembers unfold toward the open part of the bar (right-side groups open left, others open right; below vs. above on a vertical bar) and the bar makes room automatically.\n\nOn the bar, the configured click activates the selected main widget. The other click expands or collapses the group; when no main widget is set, either click expands normally."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                lineHeight: 1.5
            }
        }
    }

    // ── Create group ───────────────────────────────────────────────────────────
    StyledRect {
        width: parent.width
        height: addCol.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: addCol
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Add Group"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS
                    StyledText { text: "Name"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                    DankTextField {
                        id: nameField
                        width: parent.width
                        placeholderText: "e.g. System"
                        onTextChanged: root.newGroupName = text
                    }
                }

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS
                    StyledText { text: "Button icon"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                    DropdownIconPicker {
                        id: iconField
                        width: parent.width
                        currentIcon: "widgets"
                        onIconSelected: (name) => root.newGroupIcon = name
                    }
                }
            }

            DankButton {
                text: "Create Group"
                iconName: "add"
                onClicked: {
                    if (!root.newGroupName) {
                        ToastService.showError("Please enter a name")
                        return
                    }
                    const newId = createVariant(root.newGroupName, {
                        icon: root.newGroupIcon || "widgets",
                        label: "",
                        display: "both",
                        targets: [],
                        mainTarget: "",
                        mainClickButton: "right",
                        mainMarkerColor: "primary",
                        expandIndicatorPosition: "",
                        showArrow: true,
                        showArrowOnlyOnHover: false,
                        hideMain: false,
                        collapseOthers: false,
                        overlayExpand: false,
                        showExpandedBorder: true
                    })
                    if (newId) {
                        Qt.callLater(() => pluginService.reloadPlugin("widgetGroup"))
                        ToastService.showInfo("Group created: " + root.newGroupName)
                        root.newGroupName = ""
                        root.newGroupIcon = "widgets"
                        nameField.text = ""
                        iconField.currentIcon = "widgets"
                    } else {
                        ToastService.showError("Failed to save — plugin service unavailable")
                    }
                }
            }
        }
    }

    // ── Existing groups ─────────────────────────────────────────────────────────
    StyledRect {
        width: parent.width
        height: Math.max(80, groupsCol.implicitHeight + Theme.spacingL * 2)
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: groupsCol
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingS

            StyledText {
                text: "Your Groups"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                visible: localGroups.count === 0
                width: parent.width
                text: "No groups yet. Create one above."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            Repeater {
                model: localGroups

                delegate: StyledRect {
                    required property string vid
                    required property string vname
                    required property string vicon
                    required property int vcount
                    required property int index

                    width: groupsCol.width
                    height: gRow.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: root.editingGroupId === vid
                        ? Theme.primaryContainer
                        : (gHover.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer)

                    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

                    MouseArea {
                        id: gHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Second click on the same row collapses the editor
                            if (root.editingGroupId === vid) {
                                root.editingGroupId = ""
                                root.editingGroup = null
                                return
                            }
                            const fresh = variants.find(v => v.id === vid) || null
                            if (fresh) root._selectGroup(fresh)
                        }
                    }

                    Row {
                        id: gRow
                        anchors.left: parent.left
                        anchors.right: gDel.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingM

                        DankIcon {
                            name: vicon || "widgets"
                            size: Theme.iconSize
                            color: root.editingGroupId === vid ? Theme.onPrimaryContainer : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - Theme.iconSize - Theme.spacingM

                            StyledText {
                                text: vname || "Unnamed"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: root.editingGroupId === vid ? Theme.onPrimaryContainer : Theme.surfaceText
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            StyledText {
                                text: vcount + " widget" + (vcount === 1 ? "" : "s")
                                font.pixelSize: Theme.fontSizeSmall
                                color: root.editingGroupId === vid ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                width: parent.width
                            }
                        }
                    }

                    Rectangle {
                        id: gDel
                        z: 1
                        width: 32; height: 32; radius: 16
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        color: gDelArea.containsMouse ? Theme.error : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "delete"; size: 16
                            color: gDelArea.containsMouse ? Theme.onError : Theme.surfaceVariantText
                        }

                        MouseArea {
                            id: gDelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.editingGroupId === vid) {
                                    root.editingGroupId = ""
                                    root.editingGroup = null
                                }
                                removeVariant(vid)
                                Qt.callLater(() => pluginService.reloadPlugin("widgetGroup"))
                                ToastService.showInfo("Group removed")
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Edit selected group ─────────────────────────────────────────────────────
    StyledRect {
        width: parent.width
        height: editCol.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        visible: root.editingGroupId !== ""

        Column {
            id: editCol
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Group Settings"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS
                    StyledText { text: "Name"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                    DankTextField {
                        id: editNameField
                        width: parent.width
                        placeholderText: "Group name"
                        onEditingFinished: root._saveGroupMeta()
                    }
                }

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS
                    StyledText { text: "Button icon"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                    DropdownIconPicker {
                        id: editIconField
                        width: parent.width
                        onIconSelected: (name) => root._saveGroupMeta()
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingXS
                StyledText { text: "Button label (optional)"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                DankTextField {
                    id: editLabelField
                    width: parent.width
                    placeholderText: "Text shown on the button"
                    onEditingFinished: root._saveGroupMeta()
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacingL

                Column {
                    spacing: Theme.spacingXS
                    StyledText { text: "Button shows"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                    Row {
                        spacing: Theme.spacingS
                        Repeater {
                            model: [
                                { value: "both", label: "Icon & Text" },
                                { value: "icon", label: "Icon only"  },
                                { value: "text", label: "Text only"  }
                            ]
                            delegate: DankButton {
                                required property var modelData
                                text: modelData.label
                                buttonHeight: 32
                                backgroundColor: root.editDisplay === modelData.value ? Theme.primary : Theme.surfaceContainerHigh
                                textColor: root.editDisplay === modelData.value ? Theme.onPrimary : Theme.surfaceText
                                onClicked: root._saveDisplay(modelData.value)
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                StyledText { text: "How members expand"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                StyledText {
                    width: parent.width
                    text: "When expanded, the grouped widgets unfold toward the open part of the bar: a group on the right side opens to the left, otherwise it opens to the right (and the equivalent below/above on a vertical bar). The direction adjusts automatically to where the group sits — and the chevrons follow it — so there's nothing to configure."
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                StyledText {
                    text: "Main widget behavior"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    width: parent.width
                    text: "Choose which click activates the selected main widget, what color marks it, and where the expand/collapse symbol appears."
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                StyledText { text: "Main activation click"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                Flow {
                    width: parent.width
                    spacing: Theme.spacingS
                    Repeater {
                        model: [
                            { value: "right", label: "Right click" },
                            { value: "left", label: "Left click" }
                        ]
                        delegate: DankButton {
                            required property var modelData
                            text: modelData.label
                            buttonHeight: 32
                            backgroundColor: root.editMainClickButton === modelData.value ? Theme.primary : Theme.surfaceContainerHigh
                            textColor: root.editMainClickButton === modelData.value ? Theme.onPrimary : Theme.surfaceText
                            onClicked: root._saveMainClickButton(modelData.value)
                        }
                    }
                }

                StyledText { text: "Main marker color"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                Flow {
                    width: parent.width
                    spacing: Theme.spacingS
                    Repeater {
                        model: [
                            { value: "primary", label: "Primary" },
                            { value: "secondary", label: "Secondary" },
                            { value: "tertiary", label: "Tertiary" },
                            { value: "surface", label: "Surface" }
                        ]
                        delegate: DankButton {
                            required property var modelData
                            text: modelData.label
                            buttonHeight: 32
                            backgroundColor: root.editMainMarkerColor === modelData.value
                                ? root._markerPreviewColor(modelData.value)
                                : Theme.surfaceContainerHigh
                            textColor: root.editMainMarkerColor === modelData.value
                                ? root._markerPreviewTextColor(modelData.value)
                                : Theme.surfaceText
                            onClicked: root._saveMainMarkerColor(modelData.value)
                        }
                    }
                }

                StyledText { text: "Expand/collapse symbol position"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                Flow {
                    width: parent.width
                    spacing: Theme.spacingS
                    Repeater {
                        model: [
                            { value: "", label: "Auto" },
                            { value: "right", label: "Right" },
                            { value: "left", label: "Left" },
                            { value: "bottom", label: "Bottom" },
                            { value: "top", label: "Top" }
                        ]
                        delegate: DankButton {
                            required property var modelData
                            text: modelData.label
                            buttonHeight: 32
                            backgroundColor: root.editExpandIndicatorPosition === modelData.value ? Theme.primary : Theme.surfaceContainerHigh
                            textColor: root.editExpandIndicatorPosition === modelData.value ? Theme.onPrimary : Theme.surfaceText
                            onClicked: root._saveExpandIndicatorPosition(modelData.value)
                        }
                    }
                }

                DankToggle {
                    width: parent.width
                    text: "Show expand/collapse symbol"
                    checked: root.editShowArrow
                    onToggled: (checked) => root._saveShowArrow(checked)
                }

                DankToggle {
                    width: parent.width
                    visible: root.editShowArrow
                    text: "Show symbol only on hover"
                    description: "Keep the expand/collapse symbol hidden until the group is hovered. If the group has no icon or text, the symbol stays visible as a fallback."
                    checked: root.editShowArrowOnlyOnHover
                    onToggled: (checked) => root._saveShowArrowOnlyOnHover(checked)
                }

                DankToggle {
                    width: parent.width
                    text: "Hide main (if selected)"
                    description: "Keep the selected main widget out of the expanded member list so it does not appear twice. The main click still activates it."
                    checked: root.editHideMain
                    onToggled: (checked) => root._saveHideMain(checked)
                }

                DankToggle {
                    width: parent.width
                    text: "Collapse other groups when this opens"
                    description: "When this group expands, automatically collapse any other open group. Enable it on each group for strict one-open-at-a-time behaviour."
                    checked: root.editCollapseOthers
                    onToggled: (checked) => root._saveCollapseOthers(checked)
                }

                DankToggle {
                    width: parent.width
                    text: "Overlay when expanded (don't push other widgets)"
                    description: "Keep the bar footprint at the collapsed size when expanded — members overflow and paint on top of neighbouring widgets instead of pushing them aside. They first fill any free space in this group's own section, then spill over. Paints over reliably for a group in the centre section; a left/right group can only paint over its own section."
                    checked: root.editOverlayExpand
                    onToggled: (checked) => root._saveOverlayExpand(checked)
                }

                DankToggle {
                    width: parent.width
                    text: "Show border around expanded group"
                    description: "Draw a thin outline around the expanded group's backing so it stays delineated from the bar — useful when the bar background is opaque and a similar tone."
                    checked: root.editShowExpandedBorder
                    onToggled: (checked) => root._saveShowExpandedBorder(checked)
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outlineVariant; opacity: 0.5 }

            // Auto-collapse behaviour
            DankToggle {
                width: parent.width
                text: "Auto-collapse"
                description: "Collapse the group automatically after it has been expanded"
                checked: root.editAutoCollapse
                onToggled: (checked) => root._saveAutoCollapse(checked)
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.editAutoCollapse

                StyledText {
                    text: "Stay open for " + root.editAutoCollapseSeconds + " second" + (root.editAutoCollapseSeconds === 1 ? "" : "s")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                DankSlider {
                    width: parent.width
                    minimum: 1
                    maximum: 30
                    step: 1
                    unit: "s"
                    value: root.editAutoCollapseSeconds
                    onSliderValueChanged: (newValue) => root.editAutoCollapseSeconds = newValue
                    onSliderDragFinished: (finalValue) => root._saveAutoCollapseSeconds(finalValue)
                }

                DankToggle {
                    width: parent.width
                    text: "Only start the timer after the mouse leaves"
                    description: "The countdown pauses while you're hovering the expanded group, and (re)starts when you move away"
                    checked: root.editAutoCollapseOnLeave
                    onToggled: (checked) => root._saveAutoCollapseOnLeave(checked)
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outlineVariant; opacity: 0.5 }

            StyledText {
                text: "Member widgets (order shown when expanded)"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            StyledText {
                width: parent.width
                text: "Use the star on a member to choose the main widget. The configured click runs it; the other click expands or collapses the group."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }

            StyledText {
                visible: localMembers.count === 0
                text: "No widgets yet. Add some below."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            Repeater {
                model: localMembers

                delegate: StyledRect {
                    required property string mid
                    required property int index

                    width: editCol.width
                    height: mRow.implicitHeight + Theme.spacingS * 2
                    radius: Theme.cornerRadius
                    color: root.editingMemberIndex === index
                        ? Theme.primaryContainer
                        : (editMemberArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer)

                    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

                    // Click the row (outside the reorder/remove buttons) to change its plugin
                    MouseArea {
                        id: editMemberArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._editMember(index)
                    }

                    Row {
                        id: mRow
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingS

                        // reorder
                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 24; height: 24; radius: 4
                                color: upArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                                visible: index > 0
                                DankIcon { anchors.centerIn: parent; name: "keyboard_arrow_up"; size: 16; color: Theme.surfaceText }
                                MouseArea {
                                    id: upArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const a = root._currentMembers()
                                        const t = a[index - 1]; a[index - 1] = a[index]; a[index] = t
                                        root._saveMembers(a)
                                    }
                                }
                            }
                            Rectangle {
                                width: 24; height: 24; radius: 4
                                color: downArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                                visible: index < localMembers.count - 1
                                DankIcon { anchors.centerIn: parent; name: "keyboard_arrow_down"; size: 16; color: Theme.surfaceText }
                                MouseArea {
                                    id: downArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const a = root._currentMembers()
                                        const t = a[index + 1]; a[index + 1] = a[index]; a[index] = t
                                        root._saveMembers(a)
                                    }
                                }
                            }
                        }

                        DankIcon {
                            name: root._iconFor(mid)
                            size: Theme.iconSize - 4
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 60 - Theme.iconSize - mMain.width - mDel.width - Theme.spacingS * 6

                            StyledText {
                                text: root._nameFor(mid)
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            StyledText {
                                visible: !root._isTargetAvailable(mid)
                                text: "not available"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.error
                            }
                        }

                        Rectangle {
                            id: mMain
                            width: 32; height: 32; radius: 16
                            color: root.editMainTarget === mid
                                ? root._markerPreviewColor(root.editMainMarkerColor)
                                : (mainArea.containsMouse ? Theme.surfaceContainerHighest : "transparent")
                            border.width: root.editMainTarget === mid || mainArea.containsMouse ? 1 : 0
                            border.color: root.editMainTarget === mid
                                ? root._markerPreviewColor(root.editMainMarkerColor)
                                : Theme.outlineVariant
                            anchors.verticalCenter: parent.verticalCenter
                            DankIcon {
                                anchors.centerIn: parent
                                name: root.editMainTarget === mid ? "star" : "star_outline"
                                size: 14
                                color: root.editMainTarget === mid
                                    ? root._markerPreviewTextColor(root.editMainMarkerColor)
                                    : (mainArea.containsMouse ? root._markerPreviewColor(root.editMainMarkerColor) : Theme.surfaceVariantText)
                            }
                            MouseArea {
                                id: mainArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root._toggleMainTarget(mid)
                            }

                            Rectangle {
                                visible: mainArea.containsMouse
                                z: 1000
                                anchors.bottom: parent.top
                                anchors.bottomMargin: Theme.spacingXS
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: mMainTip.implicitWidth + Theme.spacingM
                                height: mMainTip.implicitHeight + Theme.spacingXS * 2
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.outlineVariant
                                StyledText {
                                    id: mMainTip
                                    anchors.centerIn: parent
                                    text: "Main widget toggle"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                }
                            }
                        }

                        Rectangle {
                            id: mDel
                            width: 32; height: 32; radius: 16
                            color: mDelArea.containsMouse ? Theme.error : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            DankIcon { anchors.centerIn: parent; name: "close"; size: 14; color: mDelArea.containsMouse ? Theme.onError : Theme.surfaceVariantText }
                            MouseArea {
                                id: mDelArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const a = root._currentMembers()
                                    a.splice(index, 1)
                                    root._saveMembers(a)
                                }
                            }

                            Rectangle {
                                visible: mDelArea.containsMouse
                                z: 1000
                                anchors.bottom: parent.top
                                anchors.bottomMargin: Theme.spacingXS
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: mDelTip.implicitWidth + Theme.spacingM
                                height: mDelTip.implicitHeight + Theme.spacingXS * 2
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.outlineVariant
                                StyledText {
                                    id: mDelTip
                                    anchors.centerIn: parent
                                    text: "Remove from group"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outlineVariant; opacity: 0.3 }

            StyledText {
                text: root.editingMemberIndex >= 0 ? "Change this widget" : "Add a widget"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.editingMemberIndex >= 0 ? Theme.primary : Theme.surfaceVariantText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DankDropdown {
                    id: memberPicker
                    width: parent.width - addMemberBtn.width - (cancelMemberBtn.visible ? cancelMemberBtn.width + Theme.spacingM : 0) - Theme.spacingM
                    emptyText: "Select a widget plugin…"
                    enableFuzzySearch: true
                    options: root.availableTargetNames
                    onValueChanged: (value) => {
                        const idx = root.availableTargetNames.indexOf(value)
                        root.newMemberId = idx >= 0 ? root.availableTargets[idx].id : ""
                    }
                }

                DankButton {
                    id: addMemberBtn
                    text: root.editingMemberIndex >= 0 ? "Update" : "Add"
                    iconName: root.editingMemberIndex >= 0 ? "check" : "add"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        if (!root.newMemberId) {
                            ToastService.showError("Pick a widget plugin")
                            return
                        }
                        const a = root._currentMembers()
                        const editing = root.editingMemberIndex >= 0 && root.editingMemberIndex < a.length
                        if (editing)
                            a[root.editingMemberIndex] = root.newMemberId
                        else
                            a.push(root.newMemberId)
                        root._saveMembers(a)
                        root.editingMemberIndex = -1
                        root.newMemberId = ""
                        memberPicker.currentValue = ""
                        ToastService.showInfo(editing ? "Widget changed" : "Widget added")
                    }
                }

                DankButton {
                    id: cancelMemberBtn
                    visible: root.editingMemberIndex >= 0
                    text: "Cancel"
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root._cancelMemberEdit()
                }
            }
        }
    }
}
