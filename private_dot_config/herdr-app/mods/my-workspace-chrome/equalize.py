# Gives panes in a tab equal sizes by setting their weights in the core's herdr-app document.
# Run by the mod with `python3 -c`, so it also works on another machine through `exec(..., {on})`.
#   auto <tab>         only when every pane in the tab is split the same way
#   focused <tab> <pane>  the row or column holding that pane
import json, os, socket, sys

def sock_path():
    for p in [os.environ.get("HC_SOCKET"),
              os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/nonexistent"), "herdr-core/default.sock"),
              os.path.expanduser("~/.local/state/herdr-core/default/default.sock")]:
        if p and os.path.exists(p):
            return p
    sys.exit("no herdr-core socket")

def call(method, params):
    s = socket.socket(socket.AF_UNIX)
    s.connect(sock_path())
    s.settimeout(5)
    s.sendall((json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}) + "\n").encode())
    buf = b""
    while not buf.endswith(b"\n"):
        chunk = s.recv(1 << 20)
        if not chunk:
            break
        buf += chunk
    return json.loads(buf)

def holder(node, pane):
    kids = node.get("children") or []
    if any(c.get("id") == pane for c in kids):
        return node
    for c in kids:
        found = holder(c, pane)
        if found:
            return found
    return None

mode, tab, pane = sys.argv[1], sys.argv[2], (sys.argv[3] if len(sys.argv) > 3 else None)
for _ in range(3):
    doc = call("doc.get", {"name": "herdr-app"})["result"]
    root = next((t["root"] for s in doc["value"]["spaces"] for t in s["tabs"] if t["id"] == tab), None)
    if root is None:
        sys.exit(0)
    if mode == "auto":
        kids = root.get("children") or []
        node = root if len(kids) > 1 and all(c.get("type") == "block" for c in kids) else None
    else:
        node = holder(root, pane) or root
    kids = (node or {}).get("children") or []
    if len(kids) < 2 or all((c.get("size") or {}).get("weight") == 1.0 for c in kids):
        sys.exit(0)
    for c in kids:
        c["size"] = {"weight": 1.0}
    if "result" in call("doc.set", {"name": "herdr-app", "value": doc["value"], "version": doc["version"]}):
        sys.exit(0)
sys.exit("doc.set kept failing")
