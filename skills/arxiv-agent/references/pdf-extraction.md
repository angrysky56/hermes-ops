# arXiv PDF Extraction Reference

## PyMuPDF Setup

PyMuPDF is the reliable tool for extracting text from downloaded PDFs. It may not be pre-installed in all environments.

```bash
pip install pymupdf
```

## Extraction Pattern

```python
import pymupdf

def extract_paper_meta(pdf_path):
    """Extract title, authors, and abstract from first 2 pages of an arXiv PDF."""
    doc = pymupdf.open(pdf_path)
    pages = min(2, len(doc))
    text = "\n".join(doc[page].get_text() for page in range(pages))
    
    # Title usually appears as first heading (large text at top of page 1)
    # Authors appear below title
    # Abstract is preceded by "Abstract" label
    # PDF text is messy — use loose matching
    return text
```

## Extraction Workflow (Correct Pattern)

**WRONG (hangs):**
```
terminal(command="python3 << 'PYEOF'\nimport pymupdf\n...\nPYEOF")
```

**CORRECT (foreground):** Write script to file first, then execute:
```python
# Step 1: write the extraction script
write_file(content="import pymupdf\n...\n", path="/tmp/extract.py")

# Step 2: run it foreground
terminal(command="python3 /tmp/extract.py")
```

## arXiv PDF URL Patterns

```
https://arxiv.org/pdf/{id}.pdf           # latest version
https://arxiv.org/pdf/{id}v1.pdf         # specific version
```

## Known arXiv ID Ranges (2026)

- May 2026 batch: 2605.1xxxx
- April 2026 batch: 2604.1xxxx

IDs visible in HTML list pages may not yet be indexed in the API (1-2 day lag is normal).