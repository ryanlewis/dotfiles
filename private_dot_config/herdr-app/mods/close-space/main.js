// Closes the shown space without the "Close space?" dialog. Bound to a key
// as mod.open:close-space; it opens as an invisible popup, closes the
// space with confirmed: true, then closes itself.

import { View, div } from "gpui-kit";
import { run, props, focused, closeOverlay } from "herdr";

export default class CloseSpace extends View {
  init(_props, _cx) {
    const overlay = props()?.overlay;
    const space = focused()?.space;
    if (overlay) closeOverlay(overlay);
    if (overlay && space) run("space.close", { id: space, confirmed: true });
  }

  render(_cx) {
    return div();
  }
}
