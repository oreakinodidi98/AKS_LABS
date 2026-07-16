# AI Agent Guidelines

This file contains instructions and guidelines for AI agents working on this repository.

## 🔒 Security Best Practices

**Never commit sensitive information to this repository:**
- API keys, tokens, or credentials
- Personal access tokens (PATs)
- Database connection strings with passwords
- Environment-specific configuration values

**For MCP configuration files (`mcp.json`):**
- Use placeholder values like `"YOUR_API_KEY_HERE"` or `"${API_KEY}"`
- Reference environment variables for sensitive data
- Include documentation about required environment variables

## 📋 Repository Guidelines

### Purpose
This repository is for AKS demos that can be used in VBDs and should:
- Provide a consistent structure for all VBD content repositories
- Include proper documentation for the customer
- Support MkDocs documentation generation
- Enable Learn MCP (Model Context Protocol) server integration

### Consistent Experience
- Maintain the existing folder structure 
- Don't remove placeholder folders unless explicitly instructed
- Keep the banner image and branding consistent
- Ensure all links use proper campaign codes when referencing Learn content
- SUPPORT.md should be updated with support information.
- All readme files in the repo should have updates
- All subfolder names should be reviewed for mkdocs compatibility
- Unused subfolders (e.g. that only have a README file in them) should be cleaned up before the repo is released.

### What NOT to modify without permission:
- License files (`LICENSE`, `CODE_OF_CONDUCT.md`)
- Security files (`SECURITY.md`)
- GitHub workflow files in `.github/` directory

### Issue Management
When a user reports a problem, asks a question that should be tracked, or wants to file an issue:

1. **Discover available templates** — Check `.github/ISSUE_TEMPLATE/` for any `.yml` or `.md` template files. Read them to understand what fields and labels each template expects.
2. **Match the request to a template** — Based on what the user is describing, pick the best-fit template. If no templates exist, create a plain issue.
3. **Help the user fill in the fields** — Walk through the template's required fields interactively, proposing answers where possible.
4. **Create the issue** — Use `gh issue create --template <template-file>` if a template matches, or `gh issue create` for a plain issue.
5. **Apply labels** — Check `gh label list` to see what labels exist in the repo. Apply relevant labels based on the issue type. Don't try to apply labels that don't exist.

When reviewing open issues at the start of each phase, summarize them and propose actions — this behavior already exists in the Issue Tracking and Commits section of GUIDANCE.md.
