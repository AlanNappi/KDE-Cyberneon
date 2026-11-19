#!/usr/bin/env python3
"""CyberNeon threat radar: what weighs on the machine, who uses the network and who tries to get in.

  hostiles  programs with a real CPU or memory load, grouped by program (all Firefox processes are one contact)
  traffic   download and upload rate per program, from the kernel's TCP byte counters
  events    a new USB device, a new open port, a new device on the local network; failed logins come from the journal

Only program names leave this module. Addresses and hardware addresses become salted tags that change at every boot,
and journal messages are classified here and never stored or printed.
The same file is used by both editions: imported by the Budgie HUD, run as a command by the KDE radar:
  cn-threats [--state FILE] [--usb DIR]   one JSON snapshot (the state file keeps what the next call compares with)
  cn-threats --auth                       waits for the next login event in the journal, prints it as JSON, exits
  cn-threats --quickhack NAME [--force]   closes a program of this user (quickhack from the radar), prints the result
FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
"""
import hashlib, json, os, re, select, signal, subprocess, sys, time, zlib

CLK = os.sysconf("SC_CLK_TCK")
PAGE = os.sysconf("SC_PAGE_SIZE")
PF_KTHREAD = 0x00200000
VIRTUAL_NET = ("lo", "docker", "br-", "veth", "virbr", "vnet", "tun", "tap", "wg")
INTERPRETERS = re.compile(r"^(python[0-9.]*|perl[0-9.]*|ruby[0-9.]*|node(js)?|java|bash|sh|dash|zsh|fish|lua[0-9.]*|"
                          r"php[0-9.]*|mono|gjs|electron[0-9]*)$")
SHOW, HIDE, WARN, HOT = 0.20, 0.15, 0.50, 0.85      # threat score: appears, disappears, yellow, red
MAX_HOSTILES, MAX_TRAFFIC = 8, 6
MIN_RATE = 10 * 1024                                 # bytes/s before a program gets an arrow
BUSY_NET = 16 * 1024                                 # below this the per-program count is skipped (it costs a socket walk)
EVENT_BEARING = {"auth": 315, "ssh": 290, "usb": 225, "port": 135, "lan": 45}
KNOWN_NODES = os.path.expanduser("~/.local/share/cyberneon/radar-nodes")
AUTH_CMD = ["journalctl", "-f", "-n", "0", "-q", "-o", "json", "--output-fields=SYSLOG_IDENTIFIER,_COMM,MESSAGE",
            "SYSLOG_FACILITY=4", "SYSLOG_FACILITY=10"]
# never targeted by a quickhack: the desktop session itself, its services, and this HUD
PROTECTED = re.compile(r"^(budgie-.*|gnome-session.*|gnome-shell|gnome-keyring.*|gsd-.*|Xorg|Xwayland|X|init|systemd.*|"
                       r"sd-pam|dbus-.*|at-spi.*|pipewire.*|wireplumber|pulseaudio|plasmashell|kwin_.*|ksmserver|"
                       r"kded\d*|kglobalaccel\d*|ksystemstats|kactivitymanagerd|polkit.*|nemo-desktop|lightdm|sddm.*|"
                       r"gdm.*|xdg-.*portal.*|xdg-permission-store|ibus.*|fcitx.*|login|agetty|sshd.*|sudo|su|"
                       r"cyberneon-hud|cn-threats)$")
AUTH_FAIL = re.compile(r"authentication failure|incorrect password|password check failed|FAILED SU|"
                       r"Failed (password|publickey|keyboard)|Invalid user", re.I)


def bearing(name):
    """Radar bearing in degrees: a program always shows up in the same direction."""
    return zlib.crc32(name.encode()) % 360


def clean(name):
    return re.sub(r"[^A-Za-z0-9._+-]", "", name)[:20] or "unknown"


def program_name(comm, exe="", argv=()):
    """The name a program is known by: its executable, or the script an interpreter runs.
    Without a readable executable (other users' processes) the kernel's short name is used."""
    base = os.path.basename(exe.replace(" (deleted)", "")) if exe else ""
    if not base:
        return clean(comm)
    if not INTERPRETERS.match(base):
        return clean(base[:-4] if base.endswith(".exe") else base)
    args = [a for a in argv[1:] if a]
    for i, a in enumerate(args):
        if a in ("-c", "-"):
            break
        if a == "-m":
            return clean(args[i + 1]) if i + 1 < len(args) else clean(comm)
        if a.startswith("-"):
            continue
        n = os.path.basename(a)
        for ext in (".py", ".sh", ".pl", ".rb", ".js"):
            if n.endswith(ext):
                n = n[:-len(ext)]
        return clean(n)
    return clean(comm)


def is_protected(name):
    return bool(PROTECTED.match(name))


def threat_score(cpu, mem):
    """cpu in percent of one core (as in top), mem in percent of the RAM. One busy core, or 30% of the RAM, is red."""
    return min(1.5, max(cpu / 100, mem / 30))


def threat_level(score):
    return 2 if score >= HOT else 1 if score >= WARN else 0


def size_text(b):
    return f"{b / 1073741824:.1f}G" if b >= 1073741824 else f"{b / 1048576:.0f}M"


def tag(text, n=4):
    """Salted tag: the same device gets the same tag until the next boot, and nothing more is revealed."""
    try:
        with open("/proc/sys/kernel/random/boot_id") as f:
            salt = f.read().strip()
    except OSError:
        salt = ""
    return hashlib.sha256((salt + text).encode()).hexdigest()[:n].upper()


def _private(host):
    return host.startswith(("127.", "::1", "::ffff:127.")) or host in ("localhost", "*")


def parse_sockets(text):
    """ss -Htuinp state established -> {"local peer": [proto, pid, sent, received, peer port]} (loopback skipped)."""
    out, cur = {}, None
    for line in text.splitlines():
        if line[:1] in (" ", "\t"):
            if cur is not None:
                m = re.search(r"bytes_acked:(\d+)", line)
                if m:
                    cur[2] = int(m[1])
                m = re.search(r"bytes_received:(\d+)", line)
                if m:
                    cur[3] = int(m[1])
            continue
        cur = None
        f = line.split()
        if len(f) < 5 or f[0] not in ("tcp", "udp"):
            continue
        host, _, port = f[4].rpartition(":")
        if _private(host.strip("[]")):
            continue
        m = re.search(r'users:\(\("[^"]*",pid=(\d+)', line)
        cur = [f[0], int(m[1]) if m else 0, 0, 0, port]
        out[f[3] + " " + f[4]] = cur
    return out


def parse_listen(text):
    """ss -Hltnp -> {port: pid} of the TCP ports open to the network (bound to loopback ones skipped)."""
    out = {}
    for line in text.splitlines():
        f = line.split()
        if len(f) < 4:
            continue
        host, _, port = f[3].rpartition(":")
        host = host.strip("[]")
        if not port.isdigit() or _private(host) or "%lo" in host:
            continue
        m = re.search(r'pid=(\d+)', line)
        out.setdefault(int(port), int(m[1]) if m else 0)
    return out


def parse_arp(text):
    """/proc/net/arp -> hardware addresses of the neighbours on real interfaces."""
    out = set()
    for line in text.splitlines()[1:]:
        f = line.split()
        if len(f) >= 6 and f[2] != "0x0" and f[3] != "00:00:00:00:00:00" and not f[5].startswith(VIRTUAL_NET):
            out.add(f[3].lower())
    return out


def usb_label(ifaces):
    """USB interface classes [(class, protocol)] -> what to call the device. A keyboard wins (the "BadUSB" trick)."""
    classes = {c for c, _p in ifaces}
    if ("03", "01") in ifaces:
        return "USB // KEYBOARD"
    for cls, name in (("08", "MASS STORAGE"), ("06", "PHONE OR CAMERA"), ("0e", "CAMERA"), ("01", "AUDIO"),
                      ("e0", "WIRELESS"), ("02", "NETWORK"), ("0a", "NETWORK"), ("07", "PRINTER"), ("09", "HUB")):
        if cls in classes:
            return "USB // " + name
    if ("03", "02") in ifaces:
        return "USB // MOUSE"
    if "03" in classes:
        return "USB // INPUT DEVICE"
    return "USB // DEVICE"


def classify_auth(ident, message):
    """A journal line from the auth facilities -> event text, or None. The message itself is never kept."""
    ident = (ident or "").lower()
    if not isinstance(message, str):
        return None
    if ident.startswith("sshd"):
        if message.startswith("Accepted "):
            return "SSH // REMOTE LOGIN"
        return "SSH // FAILED LOGIN" if AUTH_FAIL.search(message) else None
    if not AUTH_FAIL.search(message):
        return None
    if ident in ("sudo", "su"):
        src = ident.upper()
    elif "polkit" in ident or ident == "pkexec":
        src = "POLKIT"
    elif "screensaver" in ident or "kscreenlocker" in ident or ident == "unix_chkpwd":
        src = "LOCK SCREEN"
    else:
        src = "LOGIN"
    return f"{src} // WRONG PASSWORD"


def auth_event(line):
    """One JSON line of AUTH_CMD -> event dict, or None."""
    try:
        d = json.loads(line)
    except ValueError:
        return None
    text = classify_auth(d.get("SYSLOG_IDENTIFIER") or d.get("_COMM"), d.get("MESSAGE"))
    if not text:
        return None
    kind = "ssh" if text.startswith("SSH") else "auth"
    return {"kind": kind, "text": text, "bearing": EVENT_BEARING[kind]}


def event(kind, text):
    return {"kind": kind, "text": text, "bearing": EVENT_BEARING[kind]}


def _read(path, mode="r"):
    try:
        with open(path, mode) as f:
            return f.read()
    except OSError:
        return b"" if "b" in mode else ""


def _run(argv):
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def proc_name(pid, comm):
    exe = ""
    try:
        exe = os.readlink(f"/proc/{pid}/exe")
    except OSError:
        pass
    argv = ()
    if exe and INTERPRETERS.match(os.path.basename(exe)):
        argv = _read(f"/proc/{pid}/cmdline", "rb").decode(errors="replace").split("\0")
    return program_name(comm, exe, argv)


def _mine(pids):
    me = os.getuid()
    try:
        return all(os.stat(f"/proc/{p}").st_uid == me for p in pids)
    except OSError:
        return False


def quickhack(name, force=False):
    """Closes a program of this user. OVERLOAD (default) sends SIGTERM to the program's top processes only: their
    children follow and a browser gets to save its session. FLATLINE (force) sends SIGKILL to every process of it.
    Returns {"name", "signalled", "refused"}: refused is "PROTECTED", "NOT YOURS" or "TARGET LOST"."""
    out = {"name": name, "signalled": 0, "refused": ""}
    if is_protected(name):
        out["refused"] = "PROTECTED"
        return out
    me, mypid, found, others = os.getuid(), os.getpid(), {}, False
    for pid in os.listdir("/proc"):
        if not pid.isdigit() or int(pid) == mypid:
            continue
        data = _read(f"/proc/{pid}/stat", "rb")
        r = data.rfind(b")")
        f = data[r + 2:].split()
        if r < 0 or len(f) < 22 or int(f[6]) & PF_KTHREAD:
            continue
        if proc_name(pid, data[data.find(b"(") + 1:r].decode(errors="replace")) != name:
            continue
        try:
            if os.stat(f"/proc/{pid}").st_uid != me:
                others = True
                continue
        except OSError:
            continue
        found[int(pid)] = int(f[1])                  # pid -> parent pid
    if not found:
        out["refused"] = "NOT YOURS" if others else "TARGET LOST"
        return out
    targets = sorted(found) if force else sorted(p for p, pp in found.items() if pp not in found)
    for p in targets:
        try:
            os.kill(p, signal.SIGKILL if force else signal.SIGTERM)
            out["signalled"] += 1
        except (ProcessLookupError, PermissionError):
            pass
    if not out["signalled"]:
        out["refused"] = "TARGET LOST"
    return out


class Scanner:
    """Compares each call with the previous one. Keep the object (Budgie) or its state() between calls (KDE)."""

    def __init__(self, state=None, usb_root=None, known_path=KNOWN_NODES):
        self.usb_root = usb_root or os.environ.get("CYBERNEON_USB_ROOT") or "/sys/bus/usb/devices"
        self.known_path = known_path
        s = state or {}
        self.n = s.get("n", 0)
        self.t = s.get("t")                      # monotonic time of the previous process sample
        self.ticks = s.get("ticks", {})          # "pid/start" -> CPU ticks
        self.names = s.get("names", {})          # "pid/start" -> program name
        self.smooth = s.get("smooth", {})        # program -> smoothed threat score
        self.socks = s.get("socks", {})          # "local peer" -> [sent, received]
        self.sock_t = s.get("sock_t")
        self.net = s.get("net")                  # [time, rx, tx] of the real interfaces
        self.usb = s.get("usb")                  # USB devices seen ("port#devnum")
        self.ports = s.get("ports")              # TCP ports seen open to the network
        self.busy = s.get("busy", False)

    def state(self):
        return {k: getattr(self, k) for k in ("n", "t", "ticks", "names", "smooth", "socks", "sock_t", "net", "usb",
                                              "ports", "busy")}

    # ------------------------------------------------------------------ programs
    @staticmethod
    def _name(pid, comm):
        return proc_name(pid, comm)

    @staticmethod
    def _private_mem(pids):
        """Resident memory minus the shared part (libraries, shared buffers), so a multi-process program counts once."""
        total = 0
        for pid in pids:
            f = _read(f"/proc/{pid}/statm").split()
            if len(f) > 2:
                total += (int(f[1]) - int(f[2])) * PAGE
        return total

    def sample_procs(self, now):
        mem_total = 1
        for line in _read("/proc/meminfo").splitlines():
            if line.startswith("MemTotal:"):
                mem_total = int(line.split()[1]) * 1024
                break
        ticks, names, groups, pid_name = {}, {}, {}, {}
        first = self.t is None
        dt = (now - self.t) if not first else 1.0
        for pid in os.listdir("/proc"):
            if not pid.isdigit():
                continue
            data = _read(f"/proc/{pid}/stat", "rb")
            r = data.rfind(b")")
            f = data[r + 2:].split()
            if r < 0 or len(f) < 22 or int(f[6]) & PF_KTHREAD:
                continue
            key = pid + "/" + f[19].decode()
            t = int(f[11]) + int(f[12])
            ticks[key] = t
            name = self.names.get(key) or self._name(pid, data[data.find(b"(") + 1:r].decode(errors="replace"))
            names[key] = name; pid_name[int(pid)] = name
            g = groups.setdefault(name, [0, 0, []])
            g[0] += max(0, t - self.ticks.get(key, 0 if not first else t))
            g[1] += int(f[21]) * PAGE
            g[2].append(pid)
        self.ticks, self.names, self.t = ticks, names, now
        if first or dt <= 0:
            return [], "", "", pid_name

        hostiles, smooth = [], {}
        top_cpu = top_mem = ("", -1.0)
        for name, (dticks, rss, pids) in groups.items():
            if rss >= 0.03 * mem_total:                  # only programs that could matter pay for the second read
                rss = self._private_mem(pids)
            cpu = 100 * dticks / CLK / dt
            mem = 100 * rss / mem_total
            if cpu > top_cpu[1]:
                top_cpu = (name, cpu)
            if rss > top_mem[1]:
                top_mem = (name, rss)
            score = threat_score(cpu, mem)
            old = self.smooth.get(name)
            s = score if old is None else 0.5 * old + 0.5 * score
            if s >= HIDE:
                smooth[name] = round(s, 3)
            if s >= SHOW or (old is not None and old >= SHOW and s >= HIDE):
                hostiles.append({"name": name, "cpu": round(cpu, 1), "mem": round(mem, 1), "rss": rss,
                                 "score": round(s, 3), "level": threat_level(s), "bearing": bearing(name),
                                 "procs": len(pids), "protected": is_protected(name) or not _mine(pids)})
        self.smooth = smooth
        hostiles.sort(key=lambda h: -h["score"])
        return hostiles[:MAX_HOSTILES], top_cpu[0], top_mem[0], pid_name

    # ------------------------------------------------------------------ network
    def sample_net(self, now):
        rx = tx = 0
        for line in _read("/proc/net/dev").splitlines()[2:]:
            name, _, rest = line.partition(":")
            if name.strip().startswith(VIRTUAL_NET):
                continue
            c = rest.split()
            rx += int(c[0]); tx += int(c[8])
        down = up = 0.0
        if self.net and now > self.net[0]:
            dt = now - self.net[0]
            down = max(0.0, (rx - self.net[1]) / dt); up = max(0.0, (tx - self.net[2]) / dt)
        self.net = [now, rx, tx]
        return down, up

    def sample_traffic(self, now, down, up, pid_name):
        busy = down + up >= BUSY_NET
        if not busy and not self.busy:
            self.socks, self.sock_t = {}, None
            return []
        self.busy = busy
        socks = parse_sockets(_run(["ss", "-Htuinp", "state", "established"]))
        fresh = self.sock_t is not None and now - self.sock_t < 12
        dt = (now - self.sock_t) if fresh else 0
        rates, quic = {}, {}
        for key, (proto, pid, sent, recv, port) in socks.items():
            name = pid_name.get(pid, "system")
            if proto == "udp":
                if port == "443":
                    quic[name] = quic.get(name, 0) + 1
                continue
            if fresh:
                old = self.socks.get(key, [0, 0])
                r = rates.setdefault(name, [0.0, 0.0])
                r[0] += max(0, recv - old[1]) / dt; r[1] += max(0, sent - old[0]) / dt
        self.socks = {k: [v[2], v[3]] for k, v in socks.items() if v[0] == "tcp"}
        self.sock_t = now
        if not fresh:
            return []
        # QUIC (HTTP/3 over UDP) has no byte counters: the rest of the traffic goes to the program using it
        if quic:
            owner = max(quic, key=quic.get)
            seen_down = sum(r[0] for r in rates.values()); seen_up = sum(r[1] for r in rates.values())
            r = rates.setdefault(owner, [0.0, 0.0])
            if down - seen_down > max(64 * 1024, 0.25 * down):
                r[0] += down - seen_down
            if up - seen_up > max(64 * 1024, 0.25 * up):
                r[1] += up - seen_up
        out = [{"name": n, "down": round(d), "up": round(u), "bearing": bearing(n)}
               for n, (d, u) in rates.items() if max(d, u) >= MIN_RATE]
        out.sort(key=lambda x: -max(x["down"], x["up"]))
        return out[:MAX_TRAFFIC]

    # ------------------------------------------------------------------ sentinel
    def sample_usb(self):
        try:
            names = os.listdir(self.usb_root)
        except OSError:
            return []
        devs = {}
        for d in names:
            if re.match(r"^\d+-[\d.]+$", d):
                devs[d + "#" + _read(os.path.join(self.usb_root, d, "devnum")).strip()] = d
        events = []
        if self.usb is not None:
            for key in sorted(set(devs) - set(self.usb)):
                d = devs[key]
                ifaces = [(_read(os.path.join(self.usb_root, n, "bInterfaceClass")).strip().lower(),
                           _read(os.path.join(self.usb_root, n, "bInterfaceProtocol")).strip().lower())
                          for n in names if n.startswith(d + ":")]
                events.append(event("usb", usb_label(ifaces)))
        self.usb = sorted(devs)
        return events

    def sample_ports(self, pid_name):
        open_now = parse_listen(_run(["ss", "-Hltnp"]))
        events = []
        if self.ports is not None:
            for port in sorted(set(open_now) - set(self.ports)):
                who = pid_name.get(open_now[port], "system").upper()
                events.append(event("port", f"PORT {port} OPEN // {who}"))
            self.ports = sorted(set(self.ports) | set(open_now))     # a port reopened later is not news
        else:
            self.ports = sorted(open_now)
        return events

    def sample_lan(self):
        macs = parse_arp(_read("/proc/net/arp"))
        if not macs:
            return []
        mid = _read("/etc/machine-id").strip()
        ids = {hashlib.sha256((mid + m).encode()).hexdigest()[:16]: m for m in macs}
        first = not os.path.exists(self.known_path)
        known = set(_read(self.known_path).split())
        new = [h for h in ids if h not in known]
        if not new and not first:
            return []
        try:
            os.makedirs(os.path.dirname(self.known_path), exist_ok=True)
            with open(self.known_path, "w") as f:
                f.write("\n".join(sorted(known | set(ids))) + "\n")
        except OSError:
            return []
        if first:                                # the first time, everything already around is home
            return []
        return [event("lan", "LAN // NEW NODE " + tag(ids[h])) for h in sorted(new)]

    # ------------------------------------------------------------------ all of it
    def poll(self, sentinel=True):
        now = time.monotonic()
        self.n += 1
        hostiles, top_cpu, top_mem, pid_name = self.sample_procs(now)
        down, up = self.sample_net(now)
        traffic = self.sample_traffic(now, down, up, pid_name)
        events = []
        if sentinel:
            events += self.sample_usb()
            events += self.sample_lan()
            if self.n % 3 == 1:
                events += self.sample_ports(pid_name)
        return {"hostiles": hostiles, "traffic": traffic, "events": events, "cpu_top": top_cpu, "mem_top": top_mem,
                "down": round(down), "up": round(up)}


def wait_auth(timeout=None):
    """Runs AUTH_CMD until the first login event (or until the parent goes away). For the KDE long poll."""
    try:
        proc = subprocess.Popen(AUTH_CMD, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    except OSError:
        time.sleep(60)
        return None
    parent = os.getppid(); end = time.monotonic() + timeout if timeout else None
    try:
        while True:
            ready, _, _ = select.select([proc.stdout], [], [], 30)
            if ready:
                line = proc.stdout.readline()
                if not line:
                    time.sleep(5)
                    return None
                e = auth_event(line)
                if e:
                    return e
            elif os.getppid() != parent or (end and time.monotonic() > end):
                return None
    finally:
        proc.kill()


def main(argv):
    if "--quickhack" in argv:
        print(json.dumps(quickhack(argv[argv.index("--quickhack") + 1], "--force" in argv)))
        return
    if "--auth" in argv:
        e = wait_auth(timeout=600)                  # the caller starts it again: no helper outlives its desktop
        if e:
            print(json.dumps(e))
        return
    run = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    path = os.path.join(run, "cyberneon-threats.json")
    usb = None
    if "--state" in argv:
        path = argv[argv.index("--state") + 1]
    if "--usb" in argv:
        usb = argv[argv.index("--usb") + 1]
    try:
        with open(path) as f:
            state = json.load(f)
    except (OSError, ValueError):
        state = None
    sc = Scanner(state, usb)
    snap = sc.poll(sentinel="--no-sentinel" not in argv)
    try:
        with open(path + ".tmp", "w") as f:
            json.dump(sc.state(), f)
        os.replace(path + ".tmp", path)
        with open(os.path.join(run, "cyberneon-culprit.json"), "w") as f:     # read by the Biomonitor during an alert
            json.dump({"cpu": snap["cpu_top"], "ram": snap["mem_top"]}, f)
    except OSError:
        pass
    print(json.dumps(snap))


if __name__ == "__main__":
    main(sys.argv[1:])
