// The cases inbox as a strip below the panes, laid out like the web inbox:
// open, answered and parked cases grouped by urgency on the left; the
// selected case's body and thread in the middle; the answer on the right,
// sent with `cases answer` as the person. Refreshes whenever the cases
// store changes. Click the header to collapse it to the header and back.
// Click the panel (or press the focus key) to give it the keyboard: j/k move,
// 1-9 pick, n writes a note, cmd-enter sends, esc leaves the note. props.demo shows sample rows.
// Briefings (finished work to look over) have a view of their own, b or the
// header's Briefings chip, and as in the web inbox stay out of the counts and the red tint.
// A picked-up briefing stays listed until its agent closes it, so its answer can be withdrawn.

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex, TextView, TextareaState, Textarea, VirtualListScrollHandle, Scrollbar, v_virtual_list } from "gpui-base";
import { layout, focused, exec, run, theme, props, watchFolder, home, nextCommand, shared, setShared } from "herdr";

const STATES = "open,answered,parked,pickedup";
const GROUPS = [["blocking", "Blocking"], ["today", "Today"], ["whenever", "Whenever"]];
const BRIEFING_GROUPS = [[false, "Waiting to land"], [true, "Landed"]];
const VERDICTS = ["approve", "hold", "reject"];
// Collapsed, the block is just the header; the layout's min must allow it.
const COLLAPSED = 27;
// The case body stays readable on wide windows: capped and centred.
const BODY_WIDTH = 760;
// Panel width from which the details get their own column.
const WIDE = 1500;
// Width of the details beside the case.
const META_W = 200;
// Width of the thread beside the case.
const THREAD_W = 260;
// The largest an image in a case body is drawn.
const IMAGE_W = 640;
const IMAGE_H = 420;
// Panel width from which the thread gets its own column too: enough that the
// case text keeps about 600px beside the details and the thread.
const WIDER = 1900;
// Fixed list heights, so the list can scroll to a row from code.
const HEADING_H = 30;
// Space above every group heading but the first.
const GROUP_GAP = 16;
const ROW_H = 32;
const DEMO = [
  { id: "demo1", state: "open", kind: "decision", urgency: "blocking", title: "Pin bun or float?", worker: "bun-pins", body: "Sample case.", options: ["Pin to 1.2.3", "Float"], recommend: 1, opened_at: new Date(Date.now() - 4 * 60e3).toISOString(), events: [] },
  { id: "demo2", state: "parked", kind: "stuck", urgency: "whenever", title: "Kobo sync loses highlights", worker: "kobo", body: "Sample case.", opened_at: new Date(Date.now() - 26 * 3600e3).toISOString(), events: [] },
];

function age(iso) {
  const m = Math.max(0, Math.round((Date.now() - Date.parse(iso)) / 60e3));
  if (m < 1) return "now";
  if (m < 60) return `${m}m`;
  if (m < 48 * 60) return `${Math.round(m / 60)}h`;
  return `${Math.round(m / 1440)}d`;
}

function answered(a) {
  if (!a) return "";
  if (a.drop) return "dropped";
  if (a.choice) return `option ${a.choice}`;
  if (a.other) return "other";
  if (a.briefing) return `${a.briefing === "accept" ? "accepted" : "sent back"}${a.file?.length ? `, filed ${a.file.join(", ")}` : ""}`;
  if (a.signoff) return a.signoff;
  if (a.ack) return "acknowledged";
  if (a.rows) return a.rows.map((r) => `${r.id}: ${r.verdict}`).join(", ");
  return a.text ?? "";
}

// Herdr keeps the last terminal pane's focus border lit while the keyboard is
// here. Swap the panes' focus colour in the live layout (sizes and hidden
// nodes as they are now) so only one thing looks focused.
function lightPanes(on) {
  const tree = layout();
  let changed = false;
  const walk = (n) => {
    if (Array.isArray(n)) return n.forEach(walk);
    if (!n || typeof n !== "object") return;
    const focus = n.pane?.focus;
    if (focus && focus.color !== (on ? "accent" : "border")) {
      focus.color = on ? "accent" : "border";
      changed = true;
    }
    Object.values(n).forEach(walk);
  };
  walk(tree);
  // Through the CLI: the tree nests deeper than run() takes.
  if (changed) exec("herdr-app", ["do", "layout.set", "--layout", JSON.stringify(tree)]);
}

// A case body in parts: markdown, diff blocks (drawn here, as the markdown view
// doesn't colour them) and images alone on a line (the markdown view doesn't
// draw images). Other fenced blocks stay markdown, untouched.
function segments(body) {
  const out = [];
  let md = [];
  let fence = false;
  const flush = () => {
    if (md.join("\n").trim()) out.push({ md: md.join("\n") });
    md = [];
  };
  const lines = body.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    if (!fence && /^\s*```diff\s*$/.test(l)) {
      flush();
      const diff = [];
      while (++i < lines.length && !/^\s*```\s*$/.test(lines[i])) diff.push(lines[i]);
      out.push({ diff });
      continue;
    }
    if (/^\s*```/.test(l)) fence = !fence;
    const m = !fence && l.match(/^\s*!\[([^\]]*)\]\(([^)\s]+)\)\s*$/);
    if (m) {
      flush();
      out.push({ img: m[2], alt: m[1] });
      continue;
    }
    md.push(l);
  }
  flush();
  return out;
}

// Where an image is copied to: image() only reads files under Herdr's mods
// folder, by a path relative to Herdr's home. Not this mod's own folder: a
// change there reloads the mod.
function cachePath(src) {
  let h = 0;
  for (const ch of src) h = (h * 31 + ch.codePointAt(0)) >>> 0;
  const ext = (src.match(/\.(png|jpe?g|gif|webp|svg)(\?|$)/i)?.[1] ?? "img").toLowerCase();
  return `mods/cases-images/${h.toString(16)}.${ext}`;
}

// For the empty state, as the web inbox shows it: answers and parks you gave today and
// this week (from Monday), and cases agents closed today.
async function counts() {
  const r = await exec("cases", ["list", "--all", "--json"]);
  if (r.code !== 0) return null;
  const day = new Date();
  day.setHours(0, 0, 0, 0);
  const week = new Date(day);
  week.setDate(day.getDate() - ((day.getDay() + 6) % 7));
  const n = { today: 0, week: 0, closed: 0 };
  for (const c of JSON.parse(r.stdout).list) {
    for (const e of c.events ?? []) {
      const at = new Date(e.at);
      if (e.author === "human" && (e.event === "answer" || e.event === "park")) {
        if (at >= week) n.week++;
        if (at >= day) n.today++;
      }
      if (e.event === "close" && at >= day) n.closed++;
    }
  }
  return n;
}

export default class Cases extends View {
  init(_props, cx) {
    this.list = [];
    this.error = null;
    this.selected = null;
    this.choice = null;
    this.verdicts = {};
    this.files = new Set();
    this.rowAt = 0;
    this.view = "cases";
    this.busy = false;
    this.status = null;
    this.reply = TextareaState.new({ placeholder: "", rows: 3 });
    this.reply.on("change", (_e, cx) => cx.notify());
    // The textarea keeps enter (cmd-enter included) for itself and reports
    // cmd-enter as a submit with secondary set.
    this.reply.on("submit", (e, cx) => {
      if (e.secondary) this.send(cx);
    });
    this.handle = cx.focus_handle();
    this.pics = {};
    this.scroll = VirtualListScrollHandle.new();
    this.refresh(cx);
    cx.spawn(async (cx) => {
      for (;;) {
        await watchFolder(`${home()}/.local/share/cases`);
        this.refresh(cx);
      }
    });
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "toggle") this.toggle();
        if (c === "focus") this.focusKey();
        if (c === "briefings" || c === "inbox") this.viewKey(c, cx);
        if (c === "next" || c === "prev") {
          const [all, cur] = this.current();
          const i = all.indexOf(cur) + (c === "next" ? 1 : -1);
          if (all[i]) this.select(all[i], cx), this.reveal();
        }
        cx.notify();
      }
    });
    // Ages tick over slowly; nothing else needs a timer.
    cx.timer.every(60e3, (cx) => cx.notify());
    // Image copies unused for three days go; a case shown again fetches its own back.
    const prune = (cx) => cx.spawn(async (cx) => {
      await exec("find", [`${home()}/.config/herdr-app/mods/cases-images`, "-type", "f", "-mmin", "+4320", "-delete"]);
      this.pics = {};
      cx.notify();
    });
    prune(cx);
    cx.timer.every(3600e3, prune);
    // Losing the keyboard doesn't redraw the panel and there is no blur hook:
    // while it's lit, check four times a second so the panes light up again.
    cx.timer.every(250, (cx) => { if (this.lit && !this.handle.is_focused()) cx.notify(); });
  }

  refresh(cx) {
    if (props()?.demo) {
      this.list = DEMO;
      cx.notify();
      return;
    }
    cx.spawn(async (cx) => {
      try {
        const r = await exec("cases", ["list", "--state", STATES, "--json"]);
        if (r.code !== 0) throw new Error(r.stderr.trim() || `cases exited ${r.code}`);
        // Picked-up cases are the agents' now; only briefings stay, to withdraw an answer.
        this.list = JSON.parse(r.stdout).list.filter((c) => c.state !== "pickedup" || c.kind === "briefing");
        this.error = null;
        if (!this.list.some((c) => c.kind !== "briefing")) this.stats = await counts();
      } catch (e) {
        this.error = String(e.message ?? e);
      }
      cx.notify();
    });
  }

  collapsed() {
    return this.height !== undefined && this.height <= COLLAPSED + 4;
  }

  // Shrinks the block to its header, or back to the height it had before.
  // Opening gives it the keyboard; collapsing with the keyboard here hands it
  // back to the focused terminal.
  toggle() {
    const collapsing = !this.collapsed();
    run("layout.resize", { id: "cases", px: collapsing ? COLLAPSED : (shared("cases.height") ?? 320) });
    if (!collapsing) return this.handle.focus();
    const f = this.handle.is_focused() && focused();
    if (f?.terminal) run("pane.focus", { terminal: f.terminal });
  }

  // The focus key: expand if collapsed and take the keyboard; pressed again
  // while the panel has it, collapse.
  focusKey() {
    if (this.collapsed()) {
      this.toggle();
      this.handle.focus();
    } else if (this.handle.is_focused()) {
      this.toggle();
    } else {
      this.handle.focus();
    }
  }

  // The answer flags ready to send for c, or null while the answer is incomplete.
  sendArgs(c) {
    const note = this.reply.value().trim();
    const free = c.kind === "question" || c.kind === "stuck";
    const args = this.answerArgs(c, note);
    return args && ["answer", ...args, ...(note && !free ? ["--note", note] : [])];
  }

  send(cx) {
    const [, c] = this.current();
    if (c?.state === "parked") return this.act(c, ["resume"], cx);
    const args = c?.state === "open" && this.sendArgs(c);
    if (args) this.act(c, args, cx);
  }

  // Drop and park carry whatever is in the reply box as their note.
  withNote(args) {
    const note = this.reply.value().trim();
    return note ? [...args, "--note", note] : args;
  }
  drop(c, cx) { if (c.state === "open") this.act(c, this.withNote(["answer", "--drop"]), cx); }
  park(c, cx) {
    if (c.state === "parked") this.act(c, ["resume"], cx);
    else if (c.state === "open" && c.kind === "stuck") this.act(c, this.withNote(["park"]), cx);
  }

  // After answering c, select the next open case below it, else the first
  // open one above it; stay put when none is left.
  advance(c) {
    const [all] = this.current();
    const i = all.findIndex((x) => x.id === c.id);
    const next = [...all.slice(i + 1), ...all.slice(0, Math.max(0, i))].find((x) => x.state === "open" && x.id !== c.id);
    if (next) {
      this.selected = next.id;
      this.reveal();
    }
  }

  current() {
    const all = this.groups().flatMap(([, l]) => l);
    return [all, all.find((c) => c.id === this.selected) ?? all.find((c) => c.state === "open") ?? all[0]];
  }

  key(e, cx) {
    const [all, c] = this.current();
    // Esc steps back one level: reply box to the panel, then the panel itself
    // collapses and hands the keyboard back.
    const collapse = () => (this.handle.is_focused() && e.key === "escape" && !this.collapsed() ? (this.toggle(), true) : false);
    if (!c) {
      if (e.key === "b" && this.handle.is_focused()) return this.switchView(cx), true;
      return collapse();
    }
    if (e.key === "enter" && e.modifiers.platform) return this.send(cx), true;
    if (e.key === "escape" && !this.handle.is_focused()) {
      this.handle.focus();
      cx.notify();
      return true;
    }
    if (collapse()) return true;
    // The rest are single keys, for when the panel itself has the keyboard.
    if (!this.handle.is_focused() || e.modifiers.platform || e.modifiers.control || e.modifiers.alt) return false;
    const i = all.indexOf(c);
    if (e.key === "j" || e.key === "down") return this.select(all[Math.min(all.length - 1, i + 1)], cx), this.reveal(), true;
    if (e.key === "k" || e.key === "up") return this.select(all[Math.max(0, i - 1)], cx), this.reveal(), true;
    if (e.key === "n") return this.reply.focus(), cx.notify(), true;
    if (e.key === "b") return this.switchView(cx), true;
    if (e.key === "d") return this.drop(c, cx), true;
    if (e.key === "p") return this.park(c, cx), true;
    // Approval: a, h or r gives the marked row its verdict and moves to the
    // next; shift-a approves every row.
    const verdict = { a: "approve", h: "hold", r: "reject" }[e.key.toLowerCase()];
    if (c.state === "open" && c.kind === "approval" && verdict) {
      const rows = c.rows ?? [];
      if (e.modifiers.shift && verdict === "approve") rows.forEach((r) => (this.verdicts[r.id] = "approve"));
      else if (rows[this.rowAt]) {
        this.verdicts[rows[this.rowAt].id] = verdict;
        this.rowAt = Math.min(rows.length - 1, this.rowAt + 1);
      }
      cx.notify();
      return true;
    }
    if (c.state === "open" && c.kind === "briefing") {
      const n = e.key === "0" ? 10 : Number(e.key);
      if (e.key === "a" || e.key === "s") this.choice = e.key === "a" ? "accept" : "send_back";
      else if (Number.isInteger(n) && n >= 1 && n <= (c.left_out?.length ?? 0)) this.toggleFile(n);
      else return false;
      cx.notify();
      return true;
    }
    const n = Number(e.key);
    if (c.state === "open" && Number.isInteger(n) && n >= 1) {
      if (c.kind === "decision") {
        const count = c.options?.length ?? 0;
        if (n <= count) this.choice = n;
        else if (n === count + 1) this.choice = "other";
      }
      if (c.kind === "signoff") this.choice = n === 1 ? "accept" : n === 2 ? "changes" : this.choice;
      cx.notify();
      return true;
    }
    return false;
  }

  // The inbox and briefings keys: open on that view with the keyboard;
  // pressed again while it's shown and focused, fold the panel away.
  viewKey(key, cx) {
    const view = key === "inbox" ? "cases" : "briefings";
    if (!this.collapsed() && this.view === view && this.handle.is_focused()) return this.toggle();
    if (this.view !== view) this.switchView(cx);
    if (this.collapsed()) this.toggle();
    else this.handle.focus();
  }

  // Cases or briefings, as the web inbox's tabs.
  switchView(cx) {
    this.view = this.view === "cases" ? "briefings" : "cases";
    this.selected = null;
    this.choice = null;
    this.files = new Set();
    this.reply.set_value("");
    cx.notify();
  }

  toggleFile(n) {
    if (this.files.has(n)) this.files.delete(n);
    else this.files.add(n);
  }

  groups() {
    const byAge = (a, b) => Date.parse(a.opened_at) - Date.parse(b.opened_at);
    // Open briefings first, then the answered ones waiting for their agent.
    const briefFirst = (a, b) => (a.state === "open") === (b.state === "open") ? byAge(a, b) : a.state === "open" ? -1 : 1;
    const cases = this.list.filter((c) => c.kind !== "briefing");
    const briefings = this.list.filter((c) => c.kind === "briefing");
    const groups = this.view === "briefings"
      ? BRIEFING_GROUPS.map(([landed, label]) => [label, briefings.filter((c) => Boolean(c.landed) === landed).sort(briefFirst)])
      : GROUPS.map(([key, label]) => [label, cases.filter((c) => c.urgency === key).sort(byAge)]);
    return groups.filter(([, l]) => l.length);
  }

  // The list's rows: a header per urgency group, then its cases.
  entries() {
    return this.groups().flatMap(([label, l]) => [{ key: `h:${label}`, label, count: l.length }, ...l.map((c) => ({ key: c.id, c }))]);
  }

  // Keeps the selected case on screen after a keyboard move or an answer.
  reveal() {
    const i = this.entries().findIndex((e) => e.key === this.selected);
    if (i >= 0) this.scroll.scroll_to_item(i > 0 && this.entries()[i - 1].label ? i - 1 : i);
  }

  select(c, cx) {
    if (this.selected === c.id) return;
    this.selected = c.id;
    this.choice = null;
    this.verdicts = {};
    this.files = new Set();
    this.rowAt = 0;
    this.status = null;
    this.reply.set_value("");
    cx.notify();
  }

  // Runs one human write on the case; the store watch then refreshes the list.
  act(c, args, cx) {
    if (this.busy || c.id.startsWith("demo")) return;
    this.busy = true;
    this.status = null;
    cx.notify();
    cx.spawn(async (cx) => {
      const r = await exec("cases", [...args, c.id, "--revision", String(c.revision), "--json"]);
      this.busy = false;
      if (r.code === 0) {
        this.reply.set_value("");
        this.choice = null;
        this.verdicts = {};
        this.files = new Set();
        this.rowAt = 0;
        this.advance(c);
        this.handle.focus();
      } else {
        this.status = r.code === 4 ? "The case changed since it was shown; look again before answering." : r.stderr.trim() || `cases exited ${r.code}`;
      }
      cx.notify();
    });
  }

  // The answer flags for the current selection, or null while it is incomplete.
  answerArgs(c, note) {
    switch (c.kind) {
      case "decision":
        if (this.choice === "other") return note ? ["--other"] : null;
        return this.choice ? ["--option", String(this.choice)] : null;
      case "approval": {
        const rows = c.rows ?? [];
        return rows.length && rows.every((r) => this.verdicts[r.id]) ? rows.flatMap((r) => ["--row", `${r.id}=${this.verdicts[r.id]}`]) : null;
      }
      case "signoff":
        if (this.choice === "changes") return note ? ["--changes"] : null;
        return this.choice === "accept" ? ["--accept"] : null;
      case "fyi":
        return ["--ack"];
      case "briefing": {
        const files = [...this.files].sort((a, b) => a - b).flatMap((n) => ["--file", String(n)]);
        // Sending back needs the reason, in the note.
        if (this.choice === "send_back") return note ? ["--send-back", ...files] : null;
        return this.choice === "accept" ? ["--accept", ...files] : null;
      }
      default:
        return note ? ["--text", note] : null;
    }
  }

  answerPanel(c, t) {
    const note = this.reply.value().trim();
    const free = c.kind === "question" || c.kind === "stuck";
    const button = (id, label, onClick, primary, disabled) => {
      const off = this.busy || disabled;
      return h_flex().id(id).h(28).px(12).items_center().rounded(6).text_size(12.5).font_semibold()
        .bg(primary ? t.solid : t.raised).text_color(primary ? t.solid_foreground : t.foreground)
        .when(!primary, (el) => el.border_1().border_color(t.input)).opacity(off ? 0.45 : 1)
        .when(!off, (el) => el.cursor_pointer().hover((s) => s.opacity(0.88)).on_click((_e, cx) => onClick(cx)))
        .child(label);
    };
    // Long labels wrap; only options 1-9 have a key, so only they show one.
    const radio = (id, label, on, onClick, badge, num) => h_flex().id(id).gap(10).items_center().px(12).py(8).min_h(34).rounded(8).border_1()
      .border_color(on ? t.accent : t.border).bg(t.background).cursor_pointer().on_click((_e, cx) => { onClick(); cx.notify(); })
      .child(div().size(14).flex_none().rounded(7).border_1().border_color(on ? t.accent : t.input).when(on, (el) => el.bg(t.accent)))
      .child(div().flex_1().min_w(0).text_size(12.5).text_color(t.foreground).child(label))
      .when(Boolean(badge), (el) => el.child(div().px(6).h(18).flex().items_center().rounded(4).bg(t.accent + "26").text_size(10.5).font_semibold().text_color(t.accent).child(badge)))
      .when(num !== undefined && (typeof num === "string" || num <= 9), (el) => el.child(div().px(5).rounded(4).border_1().border_color(t.input).text_size(10.5).text_color(t.muted).child(String(num))));
    const card = (title, children) => v_flex().gap(6)
      .child(div().text_size(11.5).font_semibold().text_color(t.muted).child(title)).children(children);

    if (c.kind === "briefing" && (c.state === "answered" || c.state === "pickedup")) {
      const who = c.worker ?? "the agent";
      return v_flex().gap(12)
        .child(div().text_size(12.5).text_color(t.muted).child(`Answered: ${answered(c.answer)}${c.answer?.note ? `. Note: ${c.answer.note}` : ""}. ${c.state === "pickedup" ? `${who} picked it up and is acting on it.` : `Waiting for ${who} to pick it up.`}`))
        .child(h_flex().child(button("withdraw", "Withdraw answer", (cx) => this.act(c, ["withdraw", "--as", home().split("/").pop(), "--reason", "Withdrawn from the Herdr panel"], cx), false, false)))
        .when(Boolean(this.status), (el) => el.child(div().text_size(12).text_color(t.blocked).child(this.status)));
    }
    if (c.state === "answered") return div().text_size(12.5).text_color(t.muted).child(`Answered: ${answered(c.answer)}${c.answer?.note ? `. Note: ${c.answer.note}` : ""}. Waiting for ${c.worker ?? "the agent"} to pick it up.`);

    const parts = [];
    if (c.state === "open") {
      if (c.kind === "decision")
        parts.push(card("Choose one", [
          ...(c.options ?? []).map((o, i) => radio(`opt-${i}`, o, this.choice === i + 1, () => (this.choice = i + 1), c.recommend === i + 1 ? "Recommended" : null, i + 1)),
          radio("opt-other", "Other, see note", this.choice === "other", () => (this.choice = "other"), null, (c.options?.length ?? 0) + 1),
        ]));
      if (c.kind === "signoff")
        parts.push(card("Sign off", [
          radio("accept", "Accept", this.choice === "accept", () => (this.choice = "accept"), null, 1),
          radio("changes", "Ask for changes, see note", this.choice === "changes", () => (this.choice = "changes"), null, 2),
        ]));
      if (c.kind === "briefing") {
        parts.push(card("Judge the work", [
          radio("accept", "Accept", this.choice === "accept", () => (this.choice = "accept"), null, "a"),
          radio("send-back", "Send back, give the reason", this.choice === "send_back", () => (this.choice = "send_back"), null, "s"),
        ]));
        // Ticked items are filed as to-dos, with either verdict.
        if (c.left_out?.length)
          parts.push(card("File what was left out", c.left_out.map((item, i) => {
            const on = this.files.has(i + 1);
            return h_flex().id(`file-${i}`).gap(10).items_start().px(12).py(8).rounded(8).border_1().border_color(on ? t.accent : t.border).bg(t.background).cursor_pointer()
              .on_click((_e, cx) => { this.toggleFile(i + 1); cx.notify(); })
              .child(div().mt(2).size(14).flex_none().rounded(3).border_1().border_color(on ? t.accent : t.input).when(on, (el) => el.bg(t.accent)))
              .child(div().flex_1().min_w(0).text_size(12.5).text_color(t.foreground).child(item))
              .when(i < 10, (el) => el.child(div().px(5).rounded(4).border_1().border_color(t.input).text_size(10.5).text_color(t.muted).child(String((i + 1) % 10))));
          })));
      }
      if (c.kind === "approval")
        parts.push(card("Verdict per row  ·  a / h / r, shift-a approves all", (c.rows ?? []).map((r, i) => v_flex().gap(4).p(8).rounded(6).bg(t.background).border_1().border_color(i === this.rowAt && this.handle.is_focused() ? t.accent : t.border)
          .child(h_flex().gap(6).items_center()
            .child(div().flex_1().min_w(0).text_size(12.5).font_semibold().text_color(t.foreground).child(`${r.label}${r.by === "human" ? " (yours)" : ""}`))
            .children(VERDICTS.map((v) => h_flex().id(`v-${r.id}-${v}`).px(8).h(22).items_center().rounded(5).text_size(11.5).cursor_pointer()
              .bg(this.verdicts[r.id] === v ? t.accent : t.raised).text_color(this.verdicts[r.id] === v ? t.accent_foreground : t.foreground)
              .on_click((_e, cx) => { this.verdicts[r.id] = v; this.rowAt = i; cx.notify(); })
              .child(r.by === "human" && v === "approve" ? "Done" : v[0].toUpperCase() + v.slice(1)))))
          .child(div().text_size(11.5).text_color(t.muted).child(r.script))
          .when(Boolean(r.note), (el) => el.child(div().text_size(11.5).text_color(t.dim).child(r.note))))));
    }
    const label = c.state === "parked" ? "Note to the agent" : c.kind === "briefing" && this.choice === "send_back" ? "Reason: what to fix" : free ? (c.kind === "stuck" ? "Guidance" : "Reply") : "Note to the agent";
    parts.push(v_flex().gap(4)
      .child(h_flex().gap(6).items_center().child(div().text_size(11.5).font_semibold().text_color(t.muted).child(label)).child(div().px(5).rounded(4).border_1().border_color(t.input).text_size(10.5).text_color(t.muted).child("n")))
      .child(div().id("reply").on_mouse_down("left", (_e, cx) => cx.stop_propagation()).w_full().rounded(6).border_1().border_color(t.input).bg(t.background).p(8)
        .child(Textarea.new(this.reply).w_full().text_size(12.5).text_color(t.foreground))));

    const buttons = [];
    if (c.state === "parked") {
      buttons.push(button("resume", "Resume  p", (cx) => this.park(c, cx), true, false));
    } else {
      const args = this.sendArgs(c);
      buttons.push(button("send", `${c.kind === "fyi" ? "Acknowledge" : "Send"}  ⌘↵`, (cx) => this.act(c, args, cx), true, !args));
      if (c.kind === "stuck") buttons.push(button("park", "Park  p", (cx) => this.park(c, cx), false, false));
      buttons.push(button("drop", "Drop  d", (cx) => this.drop(c, cx), false, false));
    }
    parts.push(h_flex().gap(8).children(buttons));
    if (this.status) parts.push(div().text_size(12).text_color(t.blocked).child(this.status));
    return v_flex().gap(14).children(parts);
  }

  // Copies an image under Herdr's home: a remote one downloaded once, a local
  // one copied. Nothing is shown until the copy is there.
  loadImage(src, cx) {
    this.pics[src] = { loading: true };
    cx.spawn(async (cx) => {
      const rel = cachePath(src);
      const dest = `${home()}/.config/herdr-app/${rel}`;
      const from = src.replace(/^file:\/\//, "").replace(/^~(?=\/)/, home());
      const fetch = /^https?:\/\//.test(src) ? 'curl -fsSL --max-time 15 -o "$1" "$2"' : 'test -f "$2" && cp "$2" "$1"';
      // touch marks the copy as used, so the hourly prune keeps it. A new copy
      // larger than 1280px is shrunk to that: the panel never draws it bigger.
      const shrink = 'm=$(sips -g pixelWidth -g pixelHeight "$1" | awk \'/pixel/ { if ($2 > m) m = $2 } END { print m }\'); [ "$m" -le 1280 ] || sips -Z 1280 "$1" >/dev/null';
      const r = await exec("sh", ["-c", `{ test -s "$1" && touch "$1"; } || { mkdir -p "$(dirname "$1")" && ${fetch} && { ${shrink}; }; } && sips -g pixelWidth -g pixelHeight "$1"`, "sh", dest, from]);
      const [w, h] = ["pixelWidth", "pixelHeight"].map((k) => Number(r.stdout.match(new RegExp(`${k}: (\\d+)`))?.[1]));
      const scale = Math.min(1, IMAGE_W / w, IMAGE_H / h);
      this.pics[src] = r.code === 0 && w && h ? { path: rel, w: Math.round(w * scale), h: Math.round(h * scale) } : { error: true };
      cx.notify();
    });
  }

  body(c, t, cx) {
    return v_flex().gap(10).children(segments(c.body).map((seg, i) => {
      if (seg.md) return TextView.markdown(`body-${c.id}-${i}`, seg.md).selectable(true).text_size(13).text_color(t.foreground);
      if (seg.diff) return v_flex().py(8).rounded(6).bg(t.canvas).border_1().border_color(t.border).font_family("JetBrains Mono").text_size(12)
        .children(seg.diff.map((l) => {
          const [bg, fg] = l.startsWith("+") ? [t.ansi2 + "1f", t.ansi2] : l.startsWith("-") ? [t.ansi1 + "1f", t.ansi1] : l.startsWith("@@") ? [null, t.ansi4] : [null, t.muted];
          return div().px(12).when(Boolean(bg), (el) => el.bg(bg)).text_color(fg).child(l || " ");
        }));
      const img = this.pics[seg.img];
      if (!img) this.loadImage(seg.img, cx);
      // Shown at its own size, scaled down to fit the column.
      if (img?.path) return v_flex().gap(4).child(image(img.path).w(img.w).h(img.h).rounded(6))
        .when(Boolean(seg.alt), (el) => el.child(div().text_size(11.5).text_color(t.dim).child(seg.alt)));
      return div().px(10).py(8).rounded(6).border_1().border_color(t.border).text_size(12).text_color(t.dim)
        .child(`${img?.error ? "Image not found" : "Loading image"}: ${seg.alt || seg.img}`);
    }));
  }

  thread(c, t) {
    return (c.events ?? []).map((e) => v_flex().gap(2)
      .child(h_flex().gap(8).text_size(11.5).text_color(t.dim)
        .child(div().font_semibold().text_color(t.muted).child(e.author[0].toUpperCase() + e.author.slice(1)))
        .child(e.event)
        .child(age(e.at)))
      .child(div().text_size(12).text_color(t.muted).child(e.data?.body ?? e.data?.outcome ?? e.data?.note ?? (e.event === "answer" ? answered(e.data) : `by ${e.actor?.name ?? "?"}`))));
  }

  // Wide enough, the case's details get a column of their own between the
  // list and the case; narrower, they're a line under the title.
  detail(c, t, cx) {
    const wide = (this.width ?? 0) >= WIDE;
    const wider = (this.width ?? 0) >= WIDER;
    const cap = (s) => s[0].toUpperCase() + s.slice(1);
    const chip = (text) => div().px(6).h(18).flex().items_center().rounded(4).bg(t.raised).text_size(11).text_color(t.foreground).child(text);
    const web = () => div().id("open-web").text_color(t.accent).cursor_pointer().on_click(() => exec("cases", ["inbox", c.id])).child("Web inbox");
    const real = !c.id.startsWith("demo");
    const field = (name, value) => v_flex().gap(3)
      .child(div().text_size(11).font_semibold().text_color(t.dim).child(name))
      .child(div().text_size(12).text_color(t.foreground).child(value));
    // A function: elements are single-use, and the mark shows in two places.
    const landing = () => (c.kind === "briefing" ? [chip(c.landed ? "Landed" : "Waiting to land")] : []);
    const meta = v_flex().w(META_W).flex_none().gap(14).pt(4)
      .child(h_flex().gap(6).flex_wrap().child(chip(cap(c.kind))).children(landing()).child(chip(cap(c.urgency))).child(chip(cap(c.state))))
      .when(Boolean(c.worker), (el) => el.child(field("Worker", c.worker)))
      .when(Boolean(c.labels?.length), (el) => el.child(field("Labels", h_flex().gap(6).flex_wrap().children(c.labels.map((l) => chip(`#${l}`))))))
      .child(field("Opened", `${age(c.opened_at)} ago · ${new Date(c.opened_at).toTimeString().slice(0, 5)}`))
      .when(Boolean(c.context), (el) => el.child(field("Context", c.context)))
      .when(Boolean(c.brief), (el) => el.child(field("Brief", div().font_family("JetBrains Mono").text_size(11.5).child(c.brief))))
      .when(Boolean(c.links?.length), (el) => el.child(field("Links", v_flex().gap(3).children(c.links.map((u, i) =>
        div().id(`link-${i}`).truncate().text_color(t.accent).cursor_pointer().on_click(() => exec("open", [u])).child(u.replace(/^https?:\/\//, "")))))))
      .when(real, (el) => el.child(div().text_size(12).child(web())));
    const line = h_flex().gap(8).items_center().flex_wrap().text_size(11.5).text_color(t.muted)
      .child(chip(cap(c.kind))).children(landing()).child(chip(cap(c.urgency))).child(chip(cap(c.state)))
      .when(Boolean(c.worker), (el) => el.child(c.worker))
      .children((c.labels ?? []).map((l) => chip(`#${l}`)))
      .child(`opened ${age(c.opened_at)} ago`)
      .when(real, (el) => el.child(web()));
    const thread = v_flex().gap(10)
      .child(h_flex().gap(8).items_center().child(div().text_size(11.5).font_semibold().text_color(t.muted).child("Thread")).child(div().flex_1().h(1).bg(t.border)))
      .children(this.thread(c, t));
    // Wide, the details, the case and its thread are one block, centred in the space.
    return h_flex().flex_1().min_w(0).h_full()
      .child(v_flex().id("detail").flex_1().min_w(0).h_full().overflow_y_scrollbar().px(18).py(14)
        .child(h_flex().w_full().max_w(wide ? META_W + BODY_WIDTH + 32 + (wider ? THREAD_W + 32 : 0) : BODY_WIDTH).mx_auto().gap(32).items_start()
        .when(wide, (el) => el.child(meta))
        .child(v_flex().flex_1().min_w(0).gap(10)
        .child(div().text_size(17).font_semibold().text_color(t.foreground).child(c.title))
        .when(!wide, (el) => el.child(line).when(Boolean(c.context), (el) => el.child(div().text_size(12).text_color(t.muted).child(c.context))))
        .when(Boolean(c.body), (el) => el.child(this.body(c, t, cx)))
        .when(Boolean(c.left_out?.length), (el) => el.child(v_flex().gap(6)
          .child(h_flex().gap(8).items_center().child(div().text_size(11.5).font_semibold().text_color(t.muted).child("Left out on purpose")).child(div().flex_1().h(1).bg(t.border)))
          .children(c.left_out.map((item, i) => h_flex().gap(8).items_start().text_size(12.5)
            .child(div().w(18).flex_none().text_color(t.dim).child(`${i + 1}.`))
            .child(div().flex_1().min_w(0).text_color(t.foreground).child(item))))))
        .when(!wider, (el) => el.child(thread)))
        .when(wider, (el) => el.child(v_flex().w(THREAD_W).flex_none().pt(4).child(thread)))))
      .child(v_flex().id("answer").w(wide ? 420 : 380).flex_none().h_full().overflow_y_scrollbar().border_l(1).border_color(t.border).px(14).py(14)
        .child(this.answerPanel(c, t)));
  }

  render(cx) {
    const t = theme();
    const all = this.list.filter((c) => c.kind !== "briefing");
    const briefings = this.list.filter((c) => c.kind === "briefing" && c.state === "open").length;
    const onBriefings = this.view === "briefings";
    const [, sel] = this.current();
    const open = all.filter((c) => c.state === "open").length;
    const waiting = all.length - open;
    // Collapsed with cases to answer: the bar takes a red tint so it can't be missed.
    const alert = this.collapsed() && open > 0 && !this.error;
    const fg = alert ? t.ansi1 : t.foreground, muted = alert ? t.ansi1 + "cc" : t.muted, dim = alert ? t.ansi1 + "99" : t.dim;
    // Collapsed, no view is shown, so neither pill is lit.
    const collapsedNow = this.collapsed();
    const pill = (id, label, n, on) => h_flex().id(`${id}-pill`).px(8).h(18).items_center().rounded(9).border_1()
      .border_color(on ? t.accent : t.border).bg(on ? t.accent + "26" : t.chrome).text_color(on ? t.accent : muted)
      .hover((s) => s.text_color(on ? t.accent : fg)).cursor_pointer()
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => {
        cx.stop_propagation();
        if ((id === "briefings") !== onBriefings) this.switchView(cx);
        if (this.collapsed()) this.toggle();
      })
      .child(`${label} \u00b7 ${n}`);
    const header = h_flex().id("header").gap(8).items_center().px(14).h(26).flex_none().text_size(11.5).text_color(muted).cursor_pointer()
      .when(alert, (el) => el.bg(t.ansi1 + "26"))
      .on_click(() => this.toggle())
      .child(div().font_semibold().text_color(fg).child("Cases"))
      // The two views as pills, like the web inbox's chips: the shown one lit.
      // Clicking one shows that view (opening the bar), without folding it.
      .when(Boolean(this.error), (el) => el.child(div().child("unavailable")))
      .when(!this.error, (el) => el.child(pill("inbox", "Inbox", open, !collapsedNow && !onBriefings)).child(pill("briefings", "Briefings", briefings, !collapsedNow && onBriefings))
        .when(waiting > 0, (el) => el.child(div().child(`${waiting} with agents`))))
      .when(Boolean(props()?.demo), (el) => el.child(div().text_color(dim).child("· demo rows")));
    // One line per case: its title and age, or its state once it waits on someone else.
    const row = (c) => div().h(ROW_H).py(1).child(h_flex().size_full().gap(8).items_center().mx(6).px(10).rounded(6).cursor_pointer()
      .when(c.id === sel?.id, (el) => el.bg(t.selected)).hover((s) => s.bg(t.hover))
      .when(c.state !== "open", (el) => el.opacity(0.5))
      .child(div().flex_1().min_w(0).truncate().text_size(12.5).text_color(t.foreground).child(c.title))
      .child(div().flex_none().text_size(11).text_color(t.dim).child(
        c.state === "open" ? age(c.opened_at) : c.state)));
    const heading = (e) => h_flex().h(HEADING_H + (e.key === entries[0]?.key ? 0 : GROUP_GAP)).items_end().justify_between().px(14).pb(4).text_size(11.5).font_semibold().text_color(t.muted).child(e.label).child(String(e.count));
    const entries = this.entries();
    const focused = this.handle.is_focused();
    if (focused !== this.lit) {
      this.lit = focused;
      cx.timer.after(0, () => lightPanes(!focused));
    }
    // Expanded, the panel is a card like the agent panes, its border lit while
    // it has the keyboard. Collapsed, it stays a plain bar.
    const collapsed = this.collapsed();
    const body = v_flex().id("root").size_full().bg(t.chrome).overflow_hidden()
      .border_color(focused ? t.accent : t.border)
      .when(collapsed, (el) => el.border_t(1))
      .when(!collapsed, (el) => el.rounded(10).border_1())
      .track_focus(this.handle)
      .on_mouse_down("left", (_e, cx) => { this.handle.focus(); cx.notify(); })
      .on_key_down((e, cx) => { if (this.key(e, cx)) cx.stop_propagation(); })
      .on_size_change((size, cx) => {
        this.height = size.height;
        this.width = size.width;
        if (size.height > COLLAPSED + 40 && Math.abs((shared("cases.height") ?? 0) - size.height) > 1) setShared("cases.height", Math.round(size.height));
        cx.notify();
      })
      .child(header.child(div().flex_1())
        .when(focused && !this.collapsed(), (el) => el.child(div().text_color(t.dim).child("j/k move · b briefings · 1-9 pick · a/h/r verdict · a/s judge · n note · d drop · p park · ⌘↵ send · esc close")))
        // The key that opens and folds it, as the status bar shows ⌘P.
        .child(div().text_size(12).text_color(dim).child("\u2318."))
        // The panel sits at the bottom: up opens it, down folds it away.
        .child(div().p(3).rounded(4).text_color(dim).hover((s) => s.bg(t.hover).text_color(fg))
          .child(svg(this.collapsed() ? "mods/cases/chevron-up.svg" : "mods/workspace-chrome/chevron-down.svg").size(14))))
      .when(Boolean(this.error), (el) => el.child(div().px(14).text_size(12).text_color(t.blocked).child(this.error)))
      // Collapsed, only the header is drawn: the summary centres itself and
      // would otherwise show through the bar.
      .when(!collapsed, (el) => el.child(h_flex().flex_1().min_h(0)
        .when(entries.length > 0, (el) => el.child(div().w(320).flex_none().h_full().relative().bg(t.chrome).border_r(1).border_color(t.border)
          .child(v_virtual_list("cases-list", entries.length, entries.map((e, i) => (e.c ? ROW_H : HEADING_H + (i ? GROUP_GAP : 0))), (i) => entries[i].key,
            (range) => entries.slice(range.start, range.end).map((e) => (e.c ? row(e.c) : heading(e))))
            .track_scroll(this.scroll).size_full()
            .on_item_click((key, cx) => { const c = this.list.find((x) => x.id === key); if (c) this.select(c, cx); }))
          .child(Scrollbar.vertical("cases-list").viewport_from_layout().absolute().inset_0())))
        .when(Boolean(sel), (el) => el.child(this.detail(sel, t, cx)))
        .when(!sel && !this.error, (el) => el.child(this.clear(t, cx)))));
    return div().size_full().bg(t.chrome).when(!collapsed, (el) => el.px(8).pb(8)).child(body);
  }

  // Nothing to answer: one line saying so, with today's counts.
  clear(t, cx) {
    const n = this.stats;
    const briefings = this.list.filter((c) => c.kind === "briefing" && c.state === "open").length;
    if (this.view === "briefings")
      return v_flex().flex_1().h_full().items_center().justify_center().gap(8).p(16)
        .child(div().text_size(16).font_semibold().text_color(t.foreground).child("No briefings."))
        .child(div().id("to-cases").text_size(12.5).text_color(t.muted).underline().cursor_pointer().child("Back to cases  b").on_click((_e, cx) => this.switchView(cx)));
    const b = (v) => div().font_semibold().text_color(t.foreground).child(String(v));
    return v_flex().flex_1().h_full().items_center().justify_center().gap(8).p(16)
      .child(h_flex().gap(8).items_center().text_size(16).font_semibold().text_color(t.foreground).child(div().text_color(t.muted).child("✓")).child("Nothing needs you."))
      .when(briefings > 0, (el) => el.child(div().id("to-briefings").text_size(12.5).text_color(t.accent).cursor_pointer()
        .child(`${briefings} ${briefings === 1 ? "briefing" : "briefings"} to look over  b`).on_click((_e, cx) => this.switchView(cx))))
      .when(Boolean(n), (el) => el.child(h_flex().flex_wrap().justify_center().text_size(12.5).text_color(t.muted)
        .child("You answered\u00a0").child(b(n.today)).child("\u00a0today (").child(b(n.week)).child("\u00a0this week) · agents closed\u00a0").child(b(n.closed))))
      .when(!props()?.demo, (el) => el.child(div().id("web").text_size(12.5).text_color(t.muted).underline().cursor_pointer().child("Open the web inbox")
        .on_click(() => exec("cases", ["inbox"]))));
  }
}
