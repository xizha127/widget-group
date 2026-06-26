# Widget Group

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS) bar plugin that adds a single **collapsible button** to the bar which expands to reveal a group of other widgets inline — each keeping its own live pill and working popout.

> Status: **beta** (v0.5.0)

## Screenshots

Expanded — the group reveals its member widgets inline, with a double-chevron marking the end:

![Widget Group expanded on the bar](assets/group-expanded.png)

Collapsed — folded back into a single button:

![Widget Group collapsed to a button](assets/group-collapsed.png)

## Why

Bars get crowded. Widget Group lets you fold a cluster of widgets behind one button and reveal them on demand. Because the members render **inline in the bar window** (not in a separate popout), each member's own popout positions correctly below the bar — exactly as if it were placed directly on the bar.

## Features

- **Group any widgets** behind one bar button — both third-party widget plugins **and DMS built-in bar widgets** (clock, media, system tray, monitors, control center, …).
- Members are the **real widgets** — live pills and fully working popouts.
- **Auto-oriented expansion**: the group expands toward the open side of the bar automatically (left/right on horizontal bars, up/down on vertical) — no direction to configure.
- **Main widget** (optional): designate one member as the group's main. A configurable click of the button runs it directly; the other click expands/collapses. Optionally hide the main from the expanded list so it doesn't appear twice.
- **Expand/collapse symbols**: an unfold symbol on the button plus a matching end-cap button at the far end (group icon + collapse control), with a configurable symbol position.
- **Overlay mode** (optional): expand **without pushing** neighbouring widgets — members overflow and paint on top instead. Paints over reliably for a group in the centre section.
- **One open at a time** (optional): expanding a group can auto-collapse any other open group.
- **Readable when overlapping**: a solid backing behind the expanded group, with an optional border so it stays delineated even on opaque bars.
- **Button display**: icon, label, or both; choose the button icon from a searchable Material icon picker.
- **Auto-collapse** (optional): collapse after a configurable delay (1–30s), with an option to only start the timer once the mouse leaves the expanded group.
- **Multiple groups** via variants — each is a separate bar widget.
- Add / drag-reorder / change / remove members; collapsible editor.

## Requirements

- DankMaterialShell (quickshell-based) with the plugin system.
- Members can be DMS **built-in** bar widgets, or third-party **widget**-type plugins (those must be **enabled**).

## Install

### From the DMS plugin registry (once published)

```sh
dms plugins install widgetGroup
```

### Manual

Clone into your DMS plugins directory:

```sh
git clone https://github.com/rdannenbring/widget-group.git \
  ~/.config/DankMaterialShell/plugins/widgetGroup
```

Then enable it in **DMS Settings → Plugins**, configure a group, and add it to your bar via **Bar Settings → Add Widget**.

## Usage

1. Enable any third-party widget plugins you want to group (built-ins need no setup).
2. Enable Widget Group in **Settings → Plugins** and open its settings.
3. Create a group, then click it to edit (button icon/label/display, main widget + click action, expand/collapse symbol, overlay, one-open-at-a-time, auto-collapse).
4. Add members; use the **star** to pick the main widget and the **×** to remove. Drag the handle to reorder.
5. **Bar Settings → Add Widget** to place the group on your bar.

On the bar, click the button (▾/▴ or ‹/›) to show or hide the members.

## Notes & caveats

- Third-party members must be **widget** plugins (they have a bar pill + popout). Daemon/launcher/desktop plugins aren't applicable. DMS built-in bar widgets can also be added directly.
- **Overlay mode** keeps the collapsed footprint and paints members on top of neighbours. Because bar sections paint in a fixed order (centre on top), the "paint over" is reliable for a group in the **centre** section; a left/right group only paints over its own section. Members fill any free space in their own section first, then spill over.
- With **auto-collapse → only after mouse leaves**: if you open a member's popout and move onto that popout window, the group counts it as "mouse left" and collapses after the delay. The member's popout itself stays open.

## How it works

The group is itself a real bar widget (`PluginComponent`); each variant is one group.

For each member it instantiates that plugin's widget component once — from `PluginService.pluginWidgetComponents[id]` — injecting the bar context (`axis`, `barThickness`, `barConfig`, screen, …) the way DMS's own `WidgetHost` does. It then **proxies** the member's `horizontalBarPill` / `verticalBarPill` / `popoutContent` components and renders them **inline** in its own pill. (QML `Component`s capture their definition scope, so the proxied pill/popout keep binding to the live member instance — real data, real interactions.)

**The key design point:** members render *inline in the bar window*, not inside a popout. So each member's own popout computes its position relative to the actual bar and opens correctly below it — exactly as if the widget were placed on the bar directly. A floating dropdown panel would put members in a separate window and break that positioning; rendering inline is what makes it work.

**Files**

- `GroupWidget.qml` — the collapsible button, member layout (horizontal/vertical, expand direction), and auto-collapse timer.
- `GroupMember.qml` — one embedded member: instantiates the target widget and forwards bar context.
- `GroupSettings.qml` — the editor (variants, members, display/direction/auto-collapse).
- `DropdownIconPicker.qml` — searchable Material-symbol picker (shared with the Dropdown Menu plugin).

## License

[MIT](LICENSE)
