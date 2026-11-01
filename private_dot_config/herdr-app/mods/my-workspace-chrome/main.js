import { View, div, image, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme, run, props, window, shared, setShared, updates, layout, nextCommand, appHome, readTextFile, writeTextFile, exec, panes, spaces, agents } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

// To the rail (on macOS wide enough for the traffic lights), or back to the width it had.
function toggleSidebar() {
  const width = find(layout(), "sidebar")?.size?.px;
  if (!narrow()) setShared("sidebar.width", width);
  // Mods edited before the rail went by width still read the flag.
  setShared("sidebar.collapsed", !narrow());
  run("layout.resize", { id: "sidebar", px: narrow() ? (shared("sidebar.width") ?? 268) : window()?.platform === "macos" ? 76 : 44 });
}

// Hours and minutes, built by hand: the runtime's toLocaleTimeString ignores its options.
const clock = (d = new Date()) => `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;

// Terminal text size, kept in settings.json so it changes without the panels (app zoom scales both).
async function stepFont(command) {
  const path = `${appHome()}/settings.json`;
  const text = await readTextFile(path);
  const settings = JSON.parse(text ?? "{}");
  const size = settings.font_size ?? 13;
  settings.font_size = command === "font_reset" ? 13 : Math.min(24, Math.max(9, size + (command === "font_bigger" ? 1 : -1)));
  if (settings.font_size !== size) await writeTextFile(path, JSON.stringify(settings, null, 2) + "\n", text);
}

// Equal pane sizes: equalize.py edits the tab's weights in its machine's core document.
let equalizer = null;
async function equalize(mode, tab, pane) {
  equalizer ??= await readTextFile(`${appHome()}/mods/my-workspace-chrome/equalize.py`);
  const machine = spaces().find(s => s.tabs.some(t => t.id === tab))?.machine ?? null;
  // Remote ids carry a machine/ prefix; that machine's own document doesn't.
  const local = id => id?.split("/").pop();
  const r = await exec("python3", ["-c", equalizer, mode, local(tab), ...(pane ? [local(pane)] : [])], { on: machine });
  if (r.code !== 0) console.log(`equalize: ${r.stderr.trim()}`);
}

// The agent behind the latest toast: blocked or done, most recently changed first,
// skipping the one already shown. A done agent turns idle once looked at, so
// pressing again walks back through the rest.
function jumpToLatest() {
  const next = agents().filter((a) => (a.status === "blocked" || a.status === "done") && !a.focused).sort((a, b) => b.seq - a.seq)[0];
  if (next) run("agent.focus", { terminal: next.address });
}

export default class WorkspaceChrome extends View {
  // The clock beside the logo moves on the minute; checking often keeps it on time.
  init(_props, cx) {
    cx.timer.every(5e3, (cx) => cx.notify());
    // Only the brand copy listens, so a key steps the size once.
    if (!props()?.footer) cx.spawn(async () => { for (;;) { const c = await nextCommand(); if (c.startsWith("font_")) await stepFont(c).catch(e => console.log(`font: ${e}`));
      if (c === "jump") jumpToLatest();
      if (c === "equalize") { const p = panes().find(p => p.focused); if (p) await equalize("focused", p.tab, p.pane).catch(e => console.log(`equalize: ${e}`)); } } });
  }
  button(id, label, action) {
    const t = theme();
    return div().id(id).size(26).flex_none().flex().items_center().justify_center().rounded(6).text_color(t.muted).hover(s => s.bg(t.hover).text_color(t.foreground))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_click(action).child(label);
  }
  // A tab that gains a pane is evened out when all its panes split the same way.
  watchSplits() {
    const counts = new Map(spaces().flatMap(s => s.tabs.map(t => [t.id, t.panes])));
    if (this.counts) for (const [tab, n] of counts) if (n > (this.counts.get(tab) ?? n)) equalize("auto", tab).catch(e => console.log(`equalize: ${e}`));
    this.counts = counts;
  }
  render() {
    const t = theme();
    if (!props()?.footer) this.watchSplits();
    const collapsed = narrow();
    if (props()?.footer) {
      const row = (id, icon, label, dim, action) => h_flex().id(id).h(28).px(8).gap(9).items_center().rounded(8)
        .text_color(dim ? t.dim : t.muted).hover(s => s.bg(t.hover).text_color(t.foreground)).cursor_pointer()
        .on_click(action).child(svg(`mods/my-workspace-chrome/${icon}.svg`).size(14))
        .when(!collapsed, el => el.child(label));
      return v_flex().size_full().bg(t.chrome).border_t(1).border_color(t.border).px(8).pt(4).pb(8).text_size(13)
        .child(row("settings", "settings", "Settings", false, () => run("app.settings"))
          .when(Boolean(updates().app.ready), el => el.child(div().size(6).rounded_full().bg(t.accent))))
        .child(row("machine", "plus", "Add machine", true, () => run("mod.open", { name: "machine-add" })));
    }
    return h_flex().size_full().bg(t.chrome).pl(collapsed ? 6 : 14).pr(10).gap(4).items_center().text_size(13.5)
      .when(window()?.platform === "macos" && !collapsed, el => el.pl(76))
      .when(!collapsed, el => el.child(h_flex().flex_1().gap(8).items_center().child(image("frame/welcome/herdr.png").size(20).rounded(5)).child(div().font_semibold().text_color(t.foreground).child("Herdr"))
        .child(div().text_color(t.muted).child(clock()))))
      .when(!collapsed, el => el.child(this.button("search", svg("mods/my-workspace-chrome/search.svg").size(15), () => run("mod.open", { name: "picker" }))))
      // On the macOS rail the traffic lights fill the row; the agents list's » unfolds it.
      .when(!(collapsed && window()?.platform === "macos"), el => el.child(this.button("sidebar-toggle", svg("mods/my-workspace-chrome/sidebar.svg").size(15), toggleSidebar)));
  }
}
