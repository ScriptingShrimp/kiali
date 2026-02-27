# Kiali Issue Creation Blueprints and Best Practices

## Overview
The Kiali project uses **5 standardized issue templates** to ensure consistency and completeness. All issues should be created in the main **kiali/kiali** repository, regardless of which component (server, UI, operator, or helm charts) the work affects.

---

## 🐛 **Bug Report Template**

**When to use:** Report defects, unexpected behavior, or errors

**Label:** `bug`

**Required sections:**
1. **Describe the bug** - Clear description with screenshots if applicable
2. **Expected Behavior** - What should happen instead
3. **Steps to reproduce** - Numbered list of reproduction steps
4. **Environment** - Must include:
   - Kiali version
   - Istio version
   - Kubernetes implementation
   - Kubernetes version
   - Other notable environmental factors

**Example:**
```markdown
### Describe the bug
Service graph does not display when namespace has special characters

### Expected Behavior
Graph should render for all valid Kubernetes namespace names

### What are the steps to reproduce this bug?
1. Create namespace with underscore: `test_namespace`
2. Navigate to Graph view
3. Select the namespace from dropdown

### Environment
- **Kiali version:** v1.75.0
- **Istio version:** 1.19.3
- **Kubernetes impl:** OpenShift
- **Kubernetes version:** 1.27.6
- **Other notable environmental factors:** Running in AWS EKS
```

---

## 🔄 **Dependency Upgrade Template**

**When to use:** Propose upgrading project dependencies

**Label:** `dependencies`

**Required sections:**
1. **Which dependency needs to be upgraded, and why?**
2. **What is the current version?**
3. **Which version to upgrade to?**
4. **Changelog link** - Provide dependency changelog if available

**Example:**
```markdown
### Which dependency needs to be upgraded, and why?
React should be upgraded to address security vulnerabilities

### What is the current version of the dependency?
React 18.2.0

### Which version to upgrade to?
React 18.3.1

### Changelog link
https://github.com/facebook/react/releases/tag/v18.3.1
```

---

## 💬 **Discussion Template**

**When to use:** Features/topics that need team discussion before implementation

**Label:** `discussion needed`

**Required sections:**
1. **What do you want to discuss?**
2. **What does it improve / What problem does it solve?**
3. **What is the recommended proposal?**
4. **What are the alternate solutions?**

**Example:**
```markdown
### What do you want to discuss?
Should we implement server-side filtering for large service graphs?

### What does it improve / What problem does it solve?
Improves performance when dealing with 1000+ services by reducing client-side rendering load

### What is the recommended proposal?
Add GraphQL-like filtering API that allows clients to specify which nodes/edges to fetch

### What are the alternate solutions?
1. Client-side virtualization with progressive loading
2. Pagination-based approach
3. Pre-computed graph snapshots
```

---

## 📚 **Documentation Template**

**When to use:** Improve existing documentation or workflows

**Label:** `docs`

**Required sections:**
1. **What do you want to improve?**
2. **What is the current documentation?**
3. **What is the new documentation?**

**Example:**
```markdown
### What do you want to improve?
Add clarification on configuring custom Prometheus endpoints

### What is the current documentation?
Basic configuration example without authentication details

### What is the new documentation?
Include examples for:
- Basic auth configuration
- TLS certificate setup
- Token-based authentication
```

---

## ✨ **Feature Request Template**

**When to use:** Suggest new features or improvements

**Label:** `enhancement`

**Required sections:**
1. **What do you want to improve?**
2. **What is the current behavior?**
3. **What is the new behavior?**

**Example:**
```markdown
### What do you want to improve?
Add support for multi-cluster service mesh visualization

### What is the current behavior?
Kiali can only visualize services within a single cluster

### What is the new behavior?
Display cross-cluster traffic flows and dependencies when using Istio multi-cluster configurations
```

---

## 📋 **Best Practices**

### Before Creating an Issue

1. **Search existing issues** - Avoid duplicates by searching first
2. **Choose the right template** - Select the most appropriate template for your use case
3. **Use discussions for questions** - [GitHub Discussions](https://github.com/kiali/kiali/discussions) are better for open-ended questions

### When Creating an Issue

1. **Be specific** - Provide detailed information, not vague descriptions
2. **Include screenshots** - For UI issues, always include visual evidence
3. **Fill all required sections** - Don't skip template sections
4. **Link related issues** - Reference related issues/PRs if applicable
5. **Specify versions** - Always include accurate version information
6. **No emoticons** - Do not use emoticons/emojis in issue titles or descriptions (keep communication professional and clear)

### After Creating an Issue

1. **Wait for maintainer agreement** - Don't start work until maintainers agree the issue should be addressed
2. **Check for backlog addition** - Ensure maintainers have prioritized the work
3. **Stay responsive** - Answer clarifying questions from maintainers
4. **Watch for label changes** - Labels like `good first issue` indicate priority/complexity

### Working on Issues

- **Good first issues** - Look for [good first issue label](https://github.com/kiali/kiali/labels/good%20first%20issue) if you're new
- **Link PRs to issues** - Reference the issue number in your PR description
- **Follow style guides** - Adhere to [STYLE_GUIDE.adoc](https://github.com/kiali/kiali/blob/master/STYLE_GUIDE.adoc)
- **Disclose AI assistance** - If using AI tools, follow the [AI Policy](https://github.com/kiali/kiali/blob/master/AI_POLICY.md)

---

## 🎯 **Summary**

| Template | Use Case | Label | Key Requirement |
|----------|----------|-------|-----------------|
| Bug Report | Defects/errors | `bug` | Environment details |
| Dependency Upgrade | Update dependencies | `dependencies` | Changelog link |
| Discussion | Design discussions | `discussion needed` | Alternative solutions |
| Documentation | Doc improvements | `docs` | Current vs new docs |
| Feature Request | New features | `enhancement` | Current vs new behavior |

**Key Workflow:**
1. Create issue using appropriate template
2. Wait for maintainer feedback
3. Ensure issue is added to backlog before starting work
4. Submit PR with issue reference
5. Respond to review feedback

---

## 📄 **Full Issue Templates**

### Bug Report Template
```markdown
---
name: Bug report
about: Create a report to help us improve
title: ''
labels: 'bug'
assignees: ''
---

### Describe the bug

A clear and concise description of the bug. (provide screenshots if applicable)

### Expected Behavior

### What are the steps to reproduce this bug?

1. …
2. …
3. …

### Environment
*Learn about how to determine versions [here](https://kiali.io/docs/faq/general/#how-do-i-determine-what-version-i-am-running).*

- **Kiali version:**
- **Istio version:**
- **Kubernetes impl:**
- **Kubernetes version:**
- **Other notable environmental factors:**
```

### Dependency Upgrade Template
```markdown
---
name: Dependency Upgrade
about: Upgrade a dependency in the project
labels: 'dependencies'
---

### Which dependency needs to be upgraded, and why?

### What is the current version of the dependency?

### Which version to upgrade to?

### Changelog link

Provide the dependency changelog link, if there is one available
```

### Discussion Template
```markdown
---
name: Discussion
about: Some features/topics need to be discussed before we can work on it.
labels: 'discussion needed'
---

### What do you want to discuss?

### What does it improve / What problem does it solve?

### What is the recommended proposal?

### What are the alternate solutions?
```

### Documentation Template
```markdown
---
name: Documentation
about: Improve an existing feature or workflow
labels: 'docs'
---

### What do you want to improve?

### What is the current documentation?

### What is the new documentation?
```

### Feature Request Template
```markdown
---
name: Feature request
about: Suggest an idea for this project
title: ''
labels: 'enhancement'
assignees: ''
---

### What do you want to improve?

### What is the current behavior?

### What is the new behavior?
```

---

## 📚 **Additional Resources**

- [CONTRIBUTING.md](https://github.com/kiali/kiali/blob/master/CONTRIBUTING.md) - Full contribution guidelines
- [STYLE_GUIDE.adoc](https://github.com/kiali/kiali/blob/master/STYLE_GUIDE.adoc) - Code style requirements
- [AI_POLICY.md](https://github.com/kiali/kiali/blob/master/AI_POLICY.md) - AI-assisted contribution policy
- [GitHub Discussions](https://github.com/kiali/kiali/discussions) - Ask questions and discuss ideas
- [GitHub Issues](https://github.com/kiali/kiali/issues) - Browse existing issues
