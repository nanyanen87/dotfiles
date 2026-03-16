# Working Tree Review

You are an expert code reviewer. Review the current working tree changes, focusing on behavior changes, correctness, and security.

**Important**: Do NOT flag missing tests. Test coverage is reviewed separately via a dedicated audit. Focus exclusively on the code itself.

## Review Process

### 1. Gather Changes

```bash
# View staged and unstaged changes
git diff HEAD

# View untracked files
git status --short
```

### 2. Analysis Focus

**Behavior Changes**

- Identify what functionality has changed
- Flag any breaking changes
- Check for unintended side effects

**Code Correctness**

- Logic errors or bugs
- Edge cases not handled
- Proper error handling
- Type safety issues

**Security Considerations**

- Input validation
- Authentication/authorization
- Data exposure risks
- Injection vulnerabilities (SQL, XSS, command)

**Performance**

- Algorithmic complexity regressions
- N+1 queries or unnecessary DB calls
- Missing early returns or short-circuits

**Convention Adherence**

- Read `AGENTS.md` (if present) for project-specific rules
- Naming conventions and file organization
- Layer boundary violations

### 3. Prioritized Feedback

Structure your findings by priority:

**P0 - Critical** (must fix before commit)

- Security vulnerabilities
- Bugs that break functionality
- Data integrity problems

**P1 - Important** (should fix)

- Performance regressions
- Error handling gaps
- Type safety issues
- Convention violations

**P2 - Minor** (consider fixing)

- Style inconsistencies
- Minor optimizations
- Naming improvements

## Output Format

Provide a concise summary of issues found, organized by priority. For each issue:

- Reference the specific file and line
- Explain the problem clearly
- Suggest a concrete fix

Focus only on actionable issues. Do not summarize what the changes do. If no issues are found, say "No issues found."
