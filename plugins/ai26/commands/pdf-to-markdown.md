---
description: Convert a PDF file to markdown using the AI26 backoffice service
argument-hint: [filename.pdf]
allowed-tools: Bash, Read, Write, AskUserQuestion
---

Convert a PDF to markdown.

## Input

PDF filename: $ARGUMENTS

## Instructions

1. If no filename was provided, ask the user for the PDF filename
2. Run the conversion script:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/pdf-to-markdown.sh <filename.pdf>
   ```
3. The response is JSON with `content` (markdown) and `mimetype` fields
4. Extract and display the `content` field to the user
5. Ask if they want to save it to a file (suggest `<original-name>.md`)
