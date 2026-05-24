# Ingest Agent — Session Reference

## raw/ Path Context

The `raw/` inbox is at `/home/ty/Documents/LLM-WIKI/raw` — NOT under `wiki/`.
The wiki itself is at `/home/ty/Documents/LLM-WIKI/wiki/`.

Use absolute paths when finding files in raw/:

```bash
find /home/ty/Documents/LLM-WIKI/raw -type f
ls -la /home/ty/Documents/LLM-WIKI/raw/
```

## Clippings Structure

After ingestion, files land in:
`/home/ty/Documents/LLM-WIKI/Clippings/articles/YYYY/<filename>.md`

Example:
- Ingest `cuba-flight-tracking-shows-us-surveillance-aircraft-near-isl.md`
- Archive: `/home/ty/Documents/LLM-WIKI/Clippings/articles/2026/cuba-flight-tracking-shows-us-surveillance-aircraft-near-isl.md`

## Known wiki_ingest_raw quirks

1. **Duplicate call traps**: Calling wiki_ingest_raw on the same filename twice in one session can produce error-like messages even if the first call succeeded. If a file disappears from raw/ after the first call, that's the signal the first call succeeded — don't retry.

2. **File already ingested**: If `find /home/ty/Documents/LLM-WIKI/raw` returns nothing, it may mean:
   - File was already processed in a prior run this session
   - File was already processed in a prior cron run
   - Check `Clippings/articles/YYYY/` to verify whether the file was already archived

3. **Pipeline auto-archive**: After successful wiki_ingest_raw, the file is automatically moved to Clippings. Do NOT manually `rm` from raw/.

## Pipeline run pattern

1. `find /home/ty/Documents/LLM-WIKI/raw -type f` — discover files
2. `read_file` first file to assess content type
3. `wiki_ingest_raw(filename)` — ingest
4. `wiki_write_page` — create source summary in wiki/sources/
5. Verify raw/ is empty at end of run
6. Write ingest report
7. Update carryover.md
8. Update jobs sheet timestamp