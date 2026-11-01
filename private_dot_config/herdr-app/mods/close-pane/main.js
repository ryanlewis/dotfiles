// Closes the focused pane, like pane.close. On the last pane of the last
// tab it closes the whole space without the "Close space?" dialog. Bound
// to a key as mod.open:close-pane; it opens as an invisible popup, acts,
// then closes itself.

import { View, div } from "gpui-kit";
import { run, props, focused, panes, spaces, closeOverlay } from "herdr";

export default class ClosePane extends View {
  init(_props, _cx) {
    const overlay = props()?.overlay;
    if (!overlay) return;
    closeOverlay(overlay);
    const f = focused();
    if (!f?.pane) return run("pane.close", {});
    const space = spaces().find((s) => s.id === f.space);
    const alone = panes().filter((p) => p.tab === f.tab).length === 1 && space?.tabs.length === 1;
    if (alone) run("space.close", { id: f.space, confirmed: true });
    else run("pane.close", { pane: f.pane });
  }

  render(_cx) {
    return div();
  }
}
