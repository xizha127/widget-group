pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Modules.DankBar.Widgets
import qs.Services

// Renders ONE target's real, live bar widget inline, with full bar context
// injected. Targets can be third-party/system plugins from PluginService or
// DMS built-in bar widgets such as media controls, power menu, and system tray.
// Because this lives inside the group's bar pill (i.e. in the actual bar
// window), popout positioning is as close as possible to a normal bar widget.
Item {
    id: gm

    property var pluginService: null
    property var popoutService: null
    property string targetId: ""

    // Bar context (forwarded from the group's PluginComponent)
    property var axis: null
    property string section: "center"
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 40
    property real barSpacing: 4
    property var barConfig: null
    property var blurBarWindow: null
    property bool isMain: false

    readonly property string _pluginId: targetId.indexOf(":") >= 0 ? targetId.split(":")[0] : targetId
    readonly property string _variantId: targetId.indexOf(":") >= 0 ? targetId.split(":")[1] : ""

    readonly property var _pluginComponent: (pluginService && _pluginId && pluginService.pluginWidgetComponents)
        ? (pluginService.pluginWidgetComponents[_pluginId] || null)
        : null

    readonly property var _coreComponents: ({
        workspaceSwitcher: workspaceSwitcherComponent,
        focusedWindow: focusedWindowComponent,
        runningApps: runningAppsComponent,
        appsDock: appsDockComponent,
        clock: clockComponent,
        music: mediaComponent,
        weather: weatherComponent,
        systemTray: systemTrayComponent,
        privacyIndicator: privacyIndicatorComponent,
        clipboard: clipboardComponent,
        cpuUsage: cpuUsageComponent,
        memUsage: memUsageComponent,
        diskUsage: diskUsageComponent,
        cpuTemp: cpuTempComponent,
        gpuTemp: gpuTempComponent,
        notificationButton: notificationButtonComponent,
        battery: batteryComponent,
        layout: layoutComponent,
        controlCenterButton: controlCenterButtonComponent,
        capsLockIndicator: capsLockIndicatorComponent,
        idleInhibitor: idleInhibitorComponent,
        spacer: spacerComponent,
        separator: separatorComponent,
        network_speed_monitor: networkComponent,
        keyboard_layout_name: keyboardLayoutNameComponent,
        vpn: vpnComponent,
        notepadButton: notepadButtonComponent,
        colorPicker: colorPickerComponent,
        systemUpdate: systemUpdateComponent,
        powerMenuButton: powerMenuButtonComponent
    })

    readonly property bool _isCoreWidget: _coreComponents[targetId] !== undefined
    readonly property var _component: _pluginComponent || _coreComponents[targetId] || null
    readonly property bool ready: loader.item !== null

    readonly property var _defaultWidgetData: ({
        id: targetId,
        enabled: true,
        size: 20,
        minimumWidth: true,
        mediaSize: SettingsData.mediaSize,
        trayUseInlineExpansion: false,
        trayPopupSingleLine: SettingsData.trayPopupSingleLine,
        trayAutoOverflow: SettingsData.trayAutoOverflow,
        trayMaxVisibleItems: SettingsData.trayMaxVisibleItems,
        showNetworkIcon: SettingsData.controlCenterShowNetworkIcon,
        showBluetoothIcon: SettingsData.controlCenterShowBluetoothIcon,
        showAudioIcon: SettingsData.controlCenterShowAudioIcon,
        showMicIcon: SettingsData.controlCenterShowMicIcon,
        showBatteryIcon: SettingsData.controlCenterShowBatteryIcon,
        showBrightnessIcon: SettingsData.controlCenterShowBrightnessIcon,
        showLockIcon: SettingsData.controlCenterShowLockIcon,
        showPowerIcon: SettingsData.controlCenterShowPowerIcon,
        showSettingsIcon: SettingsData.controlCenterShowSettingsIcon,
        showDoNotDisturbIcon: SettingsData.controlCenterShowDoNotDisturbIcon,
        controlCenterGroupOrder: ["network", "vpn", "bluetooth", "audio", "microphone", "brightness", "battery", "printer", "screenSharing", "idleInhibitor", "doNotDisturb"]
    })

    implicitWidth: loader.item ? loader.item.width : 0
    implicitHeight: loader.item ? loader.item.height : 0

    function _barPosition() {
        const edge = gm.axis?.edge || "top"
        return edge === "left" ? 2 : (edge === "right" ? 3 : (edge === "top" ? 0 : 1))
    }

    function _showDankDash(tabIndex, item) {
        if (!gm.popoutService || !item)
            return
        const globalPos = item.mapToItem(null, 0, 0)
        if (gm.popoutService.toggleDankDash)
            gm.popoutService.toggleDankDash(tabIndex, globalPos.x, globalPos.y, item.width, gm.section, gm.parentScreen)
        else if (gm.popoutService.openDankDash)
            gm.popoutService.openDankDash(tabIndex, globalPos.x, globalPos.y, item.width, gm.section, gm.parentScreen)
    }

    function _popupPosition(anchorItem, sectionOverride) {
        const effectiveBarConfig = gm.barConfig
        const barPosition = gm._barPosition()
        const currentScreen = gm.parentScreen || Screen
        const globalPos = anchorItem.mapToItem(null, 0, 0)
        const spacing = effectiveBarConfig?.spacing ?? 4
        const pos = SettingsData.getPopupTriggerPosition(globalPos, currentScreen, gm.barThickness, anchorItem.width, spacing, barPosition, effectiveBarConfig)
        return {
            pos: pos,
            barPosition: barPosition,
            screen: currentScreen,
            section: sectionOverride || gm.section,
            spacing: spacing,
            barConfig: effectiveBarConfig
        }
    }

    function _requestPopout(loader, anchorItem, kind, sectionOverride) {
        if (!gm.popoutService || !loader || !anchorItem)
            return false
        loader.active = true
        if (!loader.item)
            return false
        const popout = loader.item
        const state = gm._popupPosition(anchorItem, sectionOverride)
        if ("triggerScreen" in popout)
            popout.triggerScreen = state.screen
        if (popout.setBarContext)
            popout.setBarContext(state.barPosition, state.barConfig?.bottomGap ?? 0)
        if (popout.setTriggerPosition)
            popout.setTriggerPosition(state.pos.x, state.pos.y, state.pos.width, state.section, state.screen, state.barPosition, gm.barThickness, state.spacing, state.barConfig)
        PopoutManager.requestPopout(popout, undefined, kind)
        return true
    }

    function _requestProcessList(sortBy, anchorItem, kind) {
        if (typeof DgopService !== "undefined" && DgopService.setSortBy)
            DgopService.setSortBy(sortBy)
        return gm._requestPopout(gm.popoutService.processListPopoutLoader, anchorItem, kind, "right")
    }

    function triggerMainAction() {
        const item = loader.item
        if (!item)
            return false

        switch (gm._pluginId) {
        case "controlCenterButton":
            return gm._requestPopout(gm.popoutService.controlCenterLoader, item, "controlCenter", "right")
        case "notificationButton":
            return gm._requestPopout(gm.popoutService.notificationCenterLoader, item, "notifications", "right")
        case "battery":
            return gm._requestPopout(gm.popoutService.batteryPopoutLoader, item, "battery", "right")
        case "vpn":
            return gm._requestPopout(gm.popoutService.vpnPopoutLoader, item, "vpn", "right")
        case "systemUpdate":
            return gm._requestPopout(gm.popoutService.systemUpdateLoader, item, "systemUpdate", "right")
        case "layout":
            return gm._requestPopout(gm.popoutService.layoutPopoutLoader, item, "layout", "center")
        case "clipboard":
            if (gm.popoutService.openClipboardHistory) {
                gm.popoutService.openClipboardHistory()
                return true
            }
            return false
        case "cpuUsage":
            return gm._requestProcessList("cpu", item, "cpu")
        case "memUsage":
            return gm._requestProcessList("memory", item, "memory")
        case "cpuTemp":
            return gm._requestProcessList("cpu", item, "cpu_temp")
        case "gpuTemp":
            return gm._requestProcessList("cpu", item, "gpu_temp")
        case "systemTray":
            if ("menuOpen" in item) {
                item.menuOpen = !item.menuOpen
                return true
            }
            break
        }

        if (typeof item.clicked === "function") {
            item.clicked()
            return true
        }
        if (typeof item.triggerPopout === "function") {
            item.triggerPopout()
            return true
        }
        return false
    }

    Loader {
        id: loader
        active: gm._component !== null
        sourceComponent: gm._component
        anchors.verticalCenter: parent.verticalCenter

        onLoaded: {
            if (!item)
                return
            try {
                if ("pluginId" in item)      item.pluginId = gm._pluginId
                if ("pluginService" in item) item.pluginService = gm.pluginService
                if ("popoutService" in item) item.popoutService = gm.popoutService
                if ("variantId" in item)     item.variantId = gm._variantId
                if ("variantData" in item && gm._variantId && gm.pluginService)
                    item.variantData = gm.pluginService.getPluginVariantData(gm._pluginId, gm._variantId)
            } catch (e) {
                console.warn("[widgetGroup] member injection failed for", gm.targetId, ":", e)
            }
        }
    }

    Binding { target: loader.item; when: loader.item && "axis" in loader.item;            property: "axis";            value: gm.axis;            restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "section" in loader.item;         property: "section";         value: gm.section;         restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "parentScreen" in loader.item;    property: "parentScreen";    value: gm.parentScreen;    restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "widgetThickness" in loader.item; property: "widgetThickness"; value: gm.widgetThickness; restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "barThickness" in loader.item;    property: "barThickness";    value: gm.barThickness;    restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "barSpacing" in loader.item;      property: "barSpacing";      value: gm.barSpacing;      restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "barConfig" in loader.item;       property: "barConfig";       value: gm.barConfig;       restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "blurBarWindow" in loader.item;   property: "blurBarWindow";   value: gm.blurBarWindow;   restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "widgetData" in loader.item;      property: "widgetData";      value: gm._defaultWidgetData; restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "parentWindow" in loader.item;    property: "parentWindow";    value: gm.blurBarWindow;   restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "isAtBottom" in loader.item;      property: "isAtBottom";      value: (gm.axis?.edge || "top") === "bottom"; restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "isAutoHideBar" in loader.item;   property: "isAutoHideBar";   value: gm.barConfig?.autoHide ?? false; restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "sectionAvailablePrimarySize" in loader.item; property: "sectionAvailablePrimarySize"; value: 0; restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "screenName" in loader.item;      property: "screenName";      value: gm.parentScreen?.name || ""; restoreMode: Binding.RestoreNone }
    Binding { target: loader.item; when: loader.item && "screenModel" in loader.item;     property: "screenModel";     value: gm.parentScreen?.model || ""; restoreMode: Binding.RestoreNone }

    // ── DMS built-in bar widget components ────────────────────────────────────
    // Most built-ins inherit BasePill and get their context from the bindings above.
    // A few normally receive click handlers from DankBarContent, so wire the common
    // cases through PopoutService when Widget Group has it injected.
    Component { id: workspaceSwitcherComponent; WorkspaceSwitcher {} }
    Component { id: focusedWindowComponent; FocusedApp {} }
    Component { id: runningAppsComponent; RunningApps {} }
    Component { id: appsDockComponent; AppsDock {} }

    Component {
        id: clockComponent
        Clock { onClockClicked: gm._showDankDash(0, this) }
    }

    Component {
        id: mediaComponent
        Media { onClicked: gm._showDankDash(1, this) }
    }

    Component {
        id: weatherComponent
        Weather { onClicked: gm._showDankDash(3, this) }
    }

    Component { id: systemTrayComponent; SystemTrayBar {} }
    Component { id: privacyIndicatorComponent; PrivacyIndicator {} }
    Component { id: clipboardComponent; ClipboardButton {} }
    Component { id: cpuUsageComponent; CpuMonitor {} }
    Component { id: memUsageComponent; RamMonitor {} }
    Component { id: diskUsageComponent; DiskUsage {} }
    Component { id: cpuTempComponent; CpuTemperature {} }
    Component { id: gpuTempComponent; GpuTemperature {} }
    Component { id: notificationButtonComponent; NotificationCenterButton {} }
    Component { id: batteryComponent; Battery {} }
    Component {
        id: layoutComponent
        DWLLayout {}
    }
    Component { id: controlCenterButtonComponent; ControlCenterButton {} }
    Component { id: capsLockIndicatorComponent; CapsLockIndicator {} }
    Component { id: idleInhibitorComponent; IdleInhibitor {} }

    Component {
        id: spacerComponent
        Item {
            width: gm.axis?.isVertical ? gm.widgetThickness : 20
            height: gm.axis?.isVertical ? 20 : gm.widgetThickness
            implicitWidth: width
            implicitHeight: height
        }
    }

    Component {
        id: separatorComponent
        Item {
            width: gm.axis?.isVertical ? gm.barThickness : 1
            height: gm.axis?.isVertical ? 1 : gm.barThickness
            implicitWidth: width
            implicitHeight: height
            Rectangle {
                width: gm.axis?.isVertical ? parent.width * 0.6 : 1
                height: gm.axis?.isVertical ? 1 : parent.height * 0.6
                anchors.centerIn: parent
                color: Theme.outline
                opacity: 0.3
            }
        }
    }

    Component { id: networkComponent; NetworkMonitor {} }
    Component { id: keyboardLayoutNameComponent; KeyboardLayoutName {} }
    Component { id: vpnComponent; Vpn {} }
    Component { id: notepadButtonComponent; NotepadButton {} }

    Component {
        id: colorPickerComponent
        ColorPicker {
            onColorPickerRequested: if (gm.blurBarWindow && gm.blurBarWindow.colorPickerRequested) gm.blurBarWindow.colorPickerRequested()
        }
    }

    Component { id: systemUpdateComponent; SystemUpdate {} }

    Component {
        id: powerMenuButtonComponent
        PowerMenuButton {
            onClicked: {
                if (gm.popoutService && gm.popoutService.togglePowerMenu)
                    gm.popoutService.togglePowerMenu()
            }
        }
    }
}
