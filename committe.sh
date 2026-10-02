#!/usr/bin/env bash

function committe-prompt() {
    cat <<'PROMPT'
You are a coding agent.
The user describes a change to a Git repository.
Respond with a commit message followed by a unified diff.

Example response:

Fix the doubling calculation

diff --git a/example.py b/example.py
--- a/example.py
+++ b/example.py
@@ -1,2 +1,2 @@
 def double(x):
-    return x
+    return 2 * x

Rules:
- Output only the commit message and patch.
- Do not wrap the response in Markdown code fences.
- Use an imperative commit subject of at most 50 characters.
- Add a commit-message body only when the change needs explanation.
- Use standard unified diff syntax with a/ and b/ paths.
- Include unchanged context matching the original file exactly.
- Prefer small, focused patches.
- Preserve existing documentation unless the change requires editing it.
- For new files, include "new file mode 100644" and "--- /dev/null".
- For executable new files, use mode 100755.
- For deleted files, use the appropriate deleted-file diff.
- The patch will be applied using git apply --recount.
- If clarification is needed, ask a question and output no patch.
PROMPT

    printf '\nTracked files in this repository:\n'
    git ls-files
}
function committe-mkpatch() {
    local patch_file
    patch_file=$(git rev-parse --git-path committe-patchfile) || return 1
    qwen -s "$(committe-prompt)" "$@" > "$patch_file"
}
function committe-apply() {
    local patch_file msg
    patch_file=$(git rev-parse --git-path committe-patchfile) || return 1

    if [ ! -s "$patch_file" ]; then
        echo "No patch response found."
        return 1
    fi

    if ! grep -q '^diff --git ' "$patch_file"; then
        cat "$patch_file"
        echo "No patch to apply."
        return 1
    fi

    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Commit or save existing tracked-file changes first."
        return 1
    fi

    msg=$(sed '/^diff --git/,$d' "$patch_file")

    if ! git apply --index --recount --ignore-whitespace "$patch_file"; then
        echo "git apply failed"
        return 1
    fi

    git commit -m "[committe] $msg" \
        --author="committe <committe@committe.ai>"
}

function committe() {
    committe-mkpatch "$@" && committe-apply
}
