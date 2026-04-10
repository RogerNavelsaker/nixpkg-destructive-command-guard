//! Strict Git pack - additional git protections beyond the core pack.
//!
//! This pack provides stricter protections that some users may want:
//! - Block all force pushes (even with --force-with-lease)
//! - Block rebase operations
//! - Block amending commits that have been pushed
//! - Block git filter-branch and other history rewriting
//! - Block `git add .` / `git add -A` (stage everything blindly)
//! - Block direct pushes to main/master (should use PRs)

use crate::destructive_pattern;
use crate::packs::{DestructivePattern, Pack, SafePattern};

/// Create the strict git pack.
#[must_use]
pub fn create_pack() -> Pack {
    Pack {
        id: "strict_git".to_string(),
        name: "Strict Git",
        description: "Stricter git protections: blocks force pushes, rebases, history \
                      rewriting, blind staging, and direct pushes to default branches",
        keywords: &["git"],
        safe_patterns: create_safe_patterns(),
        destructive_patterns: create_destructive_patterns(),
        keyword_matcher: None,
        safe_regex_set: None,
        safe_regex_set_is_complete: false,
    }
}

fn create_safe_patterns() -> Vec<SafePattern> {
    // No safe patterns needed: none of the destructive patterns in this pack
    // match read-only commands (git status, git log, etc.).  Previously broad
    // safe patterns like `git\s+status` were defined here, but they created a
    // bypass vector: a compound command such as `git add . ; git status` would
    // be whitelisted because the `git status` suffix matched the safe pattern,
    // hiding the destructive `git add .` prefix.
    vec![]
}

fn create_destructive_patterns() -> Vec<DestructivePattern> {
    vec![
        // Block ALL force pushes (including --force-with-lease)
        destructive_pattern!(
            "push-force-any",
            r"git\s+push\s+.*(?:--force|--force-with-lease|-f\b)",
            "Force push (even with --force-with-lease) can rewrite remote history. Disabled in strict mode."
        ),
        // Block rebase (can rewrite history)
        destructive_pattern!(
            "rebase",
            r"git\s+rebase\b",
            "git rebase rewrites commit history. Disabled in strict mode."
        ),
        // Block commit --amend (rewrites last commit)
        destructive_pattern!(
            "commit-amend",
            r"git\s+commit\s+.*--amend",
            "git commit --amend rewrites the last commit. Disabled in strict mode."
        ),
        // Block cherry-pick (can be misused)
        destructive_pattern!(
            "cherry-pick",
            r"git\s+cherry-pick\b",
            "git cherry-pick can introduce duplicate commits. Review carefully."
        ),
        // Block filter-branch (rewrites entire history)
        destructive_pattern!(
            "filter-branch",
            r"git\s+filter-branch\b",
            "git filter-branch rewrites entire repository history. Extremely dangerous!"
        ),
        // Block filter-repo (modern replacement for filter-branch)
        destructive_pattern!(
            "filter-repo",
            r"git\s+filter-repo\b",
            "git filter-repo rewrites repository history. Review carefully."
        ),
        // Block reflog expire (can lose recovery points)
        destructive_pattern!(
            "reflog-expire",
            r"git\s+reflog\s+expire",
            "git reflog expire removes reflog entries needed for recovery."
        ),
        // Block gc with aggressive options
        destructive_pattern!(
            "gc-aggressive",
            r"git\s+gc\s+.*--(?:aggressive|prune)",
            "git gc with aggressive/prune options can remove recoverable objects."
        ),
        // Block worktree remove
        destructive_pattern!(
            "worktree-remove",
            r"git\s+worktree\s+remove",
            "git worktree remove deletes a linked working tree."
        ),
        // Block submodule deinit
        destructive_pattern!(
            "submodule-deinit",
            r"git\s+submodule\s+deinit",
            "git submodule deinit removes submodule configuration."
        ),
        // Block git add . (stages everything, may include secrets, .env, build artifacts)
        // Use (?:\s|$) instead of \s*$ so we also catch compound commands like
        // "git add . && echo done" (bypass via shell chaining).
        destructive_pattern!(
            "add-all-dot",
            r"git\s+add\s+\.(?:\s|$)",
            "git add . stages everything including secrets, .env files, and build artifacts. Use 'git add <specific-files>' instead."
        ),
        // Block git add -A / git add --all (same concern as git add .)
        destructive_pattern!(
            "add-all-flag",
            r"git\s+add\s+(?:-A|--all)\b",
            "git add -A/--all stages all changes including secrets, .env files, and build artifacts. Use 'git add <specific-files>' instead."
        ),
        // Block push to master
        destructive_pattern!(
            "push-master",
            r"git\s+(?:\S+\s+)*push\s+(?:.*[\s:])?master(?:\s|$)",
            "Direct push to master is blocked. Use a feature branch and open a Pull Request."
        ),
        // Block push to main
        destructive_pattern!(
            "push-main",
            r"git\s+(?:\S+\s+)*push\s+(?:.*[\s:])?main(?:\s|$)",
            "Direct push to main is blocked. Use a feature branch and open a Pull Request."
        ),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::packs::test_helpers::*;

    #[test]
    fn test_add_all_dot() {
        let pack = create_pack();
        assert_blocks(&pack, "git add .", "stages everything");
        // Chained commands must still be caught (bypass vector)
        assert_blocks(&pack, "git add . && echo done", "stages everything");
        assert_blocks(&pack, "git add . ; git status", "stages everything");
        assert_blocks(&pack, "git add . | cat", "stages everything");
        // Trailing whitespace
        assert_blocks(&pack, "git add . ", "stages everything");
        // Should not match when adding specific dotfiles or paths starting with .
        assert_allows(&pack, "git add .gitignore");
        assert_allows(&pack, "git add ./src/main.rs");
        assert_allows(&pack, "git add .env.example");
    }

    #[test]
    fn test_add_all_flag() {
        let pack = create_pack();
        assert_blocks(&pack, "git add -A", "stages all changes");
        assert_blocks(&pack, "git add --all", "stages all changes");
        // Should not match unrelated flags
        assert_allows(&pack, "git add -p");
        assert_allows(&pack, "git add --patch");
    }

    #[test]
    fn test_push_master() {
        let pack = create_pack();
        assert_blocks(
            &pack,
            "git push origin master",
            "Direct push to master is blocked",
        );
        assert_blocks(&pack, "git push master", "Direct push to master is blocked");
        assert_blocks(
            &pack,
            "git push origin HEAD:master",
            "Direct push to master is blocked",
        );
        assert_blocks(
            &pack,
            "git push origin master:master",
            "Direct push to master is blocked",
        );

        // These should be allowed (unless blocked by other rules)
        assert_allows(&pack, "git push origin feature-master");
        assert_allows(&pack, "git push origin master-fix");
    }

    #[test]
    fn test_push_main() {
        let pack = create_pack();
        assert_blocks(
            &pack,
            "git push origin main",
            "Direct push to main is blocked",
        );
        assert_blocks(&pack, "git push main", "Direct push to main is blocked");
        assert_blocks(
            &pack,
            "git push origin HEAD:main",
            "Direct push to main is blocked",
        );
        assert_blocks(
            &pack,
            "git push origin main:main",
            "Direct push to main is blocked",
        );

        // These should be allowed (unless blocked by other rules)
        assert_allows(&pack, "git push origin feature-main");
        assert_allows(&pack, "git push origin main-fix");
        assert_allows(&pack, "git push origin maintain");
    }
}
