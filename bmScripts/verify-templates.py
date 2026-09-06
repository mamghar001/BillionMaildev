#!/usr/bin/env python3
import re, os, json, sys, urllib.request
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
ENV_FILE = SCRIPT_DIR / ".env"

def load_env():
    env = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip()
    return env

env = load_env()
API_URL = env.get("API_URL", "https://mail.moescale.site")
TOKEN_FILE = env.get("BM_TOKEN_FILE") or str(SCRIPT_DIR / ".env_token")
try:
    TOKEN = open(TOKEN_FILE).read().strip()
except Exception as e:
    print("Cannot read token from " + TOKEN_FILE + ": " + str(e))
    sys.exit(1)

def api_get(path):
    url = API_URL + path
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + TOKEN})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

def check_balanced_braces(text):
    issues = []
    count = 0
    for i, c in enumerate(text):
        if c == "{":
            count += 1
        elif c == "}":
            count -= 1
            if count < 0:
                issues.append("Unexpected closing brace at position " + str(i))
                count = 0
    if count > 0:
        issues.append("Missing " + str(count) + " closing brace(s)")
    return issues

def check_spintax_placement(text):
    issues = []
    for block in re.findall(r"<style[^>]*>.*?</style>", text, re.DOTALL | re.IGNORECASE):
        if "{" in block and "|" in block:
            issues.append("Spintax inside <style> block (wont work)")
    for block in re.findall(r"<script[^>]*>.*?</script>", text, re.DOTALL | re.IGNORECASE):
        if "{" in block and "|" in block:
            issues.append("Spintax inside <script> block (wont work)")
    return issues

def check_spintax_structure(text):
    issues = []
    i = 0
    n = len(text)
    while i < n:
        if text[i] == "{":
            j = i + 1
            has_pipe = False
            depth = 1
            while j < n and depth > 0:
                if text[j] == "{":
                    depth += 1
                elif text[j] == "}":
                    depth -= 1
                if depth == 1 and text[j] == "|":
                    has_pipe = True
                j += 1
            if has_pipe and depth > 0:
                snippet = text[i:i+50].replace(chr(10), " ")
                issues.append("Unclosed spintax at pos " + str(i) + ": " + snippet + "...")
        i += 1
    return issues

def check_subscriber_if_coverage(text):
    issues = []
    bare_pattern = re.compile(r"\{\{[^}]*\}\}")
    for m in bare_pattern.finditer(text):
        var = m.group()
        inner = var[2:-2].strip()
        if re.match(r"^\.(Subscriber|Task|API)\s*\.\w+", inner):
            pos = m.start()
            before = text[:pos]
            opens = [x.start() for x in re.finditer(r"\{\{(?:\s*#)?\s*if\b", before)]
            ends  = [x.start() for x in re.finditer(r"\{\{end\}\}", before)]
            stack = list(opens)
            for e in sorted(ends):
                if stack and stack[-1] < e:
                    stack.pop()
            in_if_block = (len(stack) > 0)
            if not in_if_block:
                issues.append("Bare {{.Subscriber.xxx}} without if condition: " + var)
    return issues

def check_template_variable_prefix(text):
    issues = []
    all_vars = re.findall(r"\{\{[^}]+\}\}", text)
    for var in all_vars:
        inner = var[2:-2].strip()
        if inner.startswith("#"):
            continue
        if re.match(r"^(?:\s*#)?\s*if\s", inner):
            continue
        if re.match(r"^\s*else", inner):
            continue
        if re.match(r"^\s*end\b", inner):
            continue
        if re.match(r"^\s*range\s", inner):
            continue
        valid = (
            re.match(r"^\.(Subscriber|Task|API)\s*\.\w+", inner) or
            inner == "UnsubscribeURL" or
            re.match(r"^UnsubscribeURL\s+\.", inner) or
            re.match(r"^\.(Subscriber|Task|API)$", inner)
        )
        if not valid:
            issues.append("Invalid {{}} syntax: " + var)
    return issues

def check_if_conditions_closed(text):
    issues = []
    opens = [m.start() for m in re.finditer(r"\{\{(?:\s*#)?\s*if\b", text)]
    ends  = [m.start() for m in re.finditer(r"\{\{end\}\}", text)]
    stack = list(opens)
    for e in sorted(ends):
        if stack:
            stack.pop()
        else:
            issues.append("Extra {{end}} at position " + str(e))
    for pos in stack:
        issues.append("Unclosed {{if}} at position " + str(pos))
    return issues

def verify_template(tid, name, subject, html_content):
    errors = []
    for text, label in [(subject, "subject"), (html_content, "body")]:
        if not text:
            continue
        errors += [(label, e) for e in check_balanced_braces(text)]
        errors += [(label, e) for e in check_spintax_placement(text)]
        errors += [(label, e) for e in check_spintax_structure(text)]
        errors += [(label, e) for e in check_subscriber_if_coverage(text)]
        errors += [(label, e) for e in check_template_variable_prefix(text)]
        errors += [(label, e) for e in check_if_conditions_closed(text)]
    return errors

def main():
    print("=" * 60)
    print("  BillionMail Template Verifier")
    print("=" * 60)

    all_templates = []
    page = 1
    page_size = 50

    while True:
        try:
            r = api_get("/api/email_template/list?page=" + str(page) + "&page_size=" + str(page_size))
            if r.get("code") == 0 and r.get("data"):
                items = r["data"].get("list", r["data"])
                if not items:
                    break
                if isinstance(items, dict):
                    items = [items]
                all_templates.extend(items)
                total = r["data"].get("total", len(items))
                if len(all_templates) >= total:
                    break
                page += 1
            else:
                break
        except Exception as e:
            print("API error: " + str(e))
            sys.exit(1)

    print("")
    print("Checking " + str(len(all_templates)) + " templates...")
    print("")

    passed = 0
    failed = 0

    for t in all_templates:
        tid   = t.get("id", "?")
        name  = t.get("temp_name") or t.get("name", "Template " + str(tid))
        subject = t.get("subject") or ""
        html   = t.get("html_content") or t.get("content") or ""

        errs = verify_template(tid, name, subject, html)

        if errs:
            failed += 1
            print("Template " + str(tid) + " - " + name)
            for label, e in errs:
                print("  [" + label + "] " + e)
            print("")
        else:
            passed += 1
            print("PASS Template " + str(tid) + " - " + name)

    print("=" * 60)
    print("  Results: " + str(passed) + " passed  |  " + str(failed) + " failed")
    print("=" * 60)

    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()