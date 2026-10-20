# Wiki

A wiki engine written in PL/SQL for the PL/SQL Web Toolkit, by Dan Bailey (2007; rewritten
October 2026). It runs under ORDS, mod_plsql or owart unchanged:

- pages kept as revisions, with history, restore, rename (links to the page follow it), delete
  and purge;
- `[[Page]]` and `[[Page|text]]` links, search, and a list of the pages that link to a page;
- a WYSIWYG editor (contenteditable, no libraries) with an HTML view and a form builder;
- **page forms**: a form named `userform` on a page; each Save is kept as a record of the page,
  and opening a record fills the form again for changes;
- **database forms**: `dbtable="T" dbpk="ID"` on the form and fields named `DB_COLUMN`
  (`DBDT_COLUMN` for dates) insert or update table `T` -- only a table listed in
  `DDG_WIKI_FORM_TABLES`;
- page scripts (`{script}...{/script}`), owner locks, hiding a page from others' searches, and
  email of a page;
- **export**: `[Export]` downloads a page as a standalone HTML file (its styles, links back to
  the wiki, no page scripts), and the Records page downloads a page's records as CSV -- a row per
  record, a column per field, readable by a spreadsheet as UTF-8, with formula-like values kept
  as text;
- **export the whole wiki** (administrators, from List of Documents): a SQL script that loads the
  wiki into another one -- the current pages, or every revision with the form records -- keeping
  editors, owners, locks and dates. Run it with SQL*Plus, SQLcl or SQL Developer in the other
  wiki's schema; a page that already exists there gets the loaded versions as new revisions, so
  nothing is overwritten. It doubles as a backup;
- **a page inside another page**: `p_extralite=Y` shows a document without the wiki's bar
  and footer (for a frame), and its `[[links]]` keep it so; `web_wiki.embed(p_topic)` writes
  just the content `<div class="wiki-content">` -- call it from a page of your own where the
  content goes, or fetch `/<path>/web_wiki.embed?p_topic=Home` from a script -- with links to
  the wiki's full pages and no page scripts; `web_wiki.embed_html` returns the same as a CLOB;
- **the wiki as web pages** (administrators, from List of Documents): a `.zip` with a contents
  page and a page per document, `[[links]]` between them, to read offline. Written in PL/SQL with
  UTL_COMPRESS and UTL_RAW -- no Java, no files on the server.

Live, read-only, at **sqling.com/web-toolkit/demo/wiki/**; the copy that can be edited -- sign
in as `EDITOR` (the default), `READER` or `ADMIN` from the link on Home to see what each security
level may do -- is in Pro, at /pro/owart/wiki/.

## Files, in install order

| File | What it is |
|---|---|
| `web_wiki.ddl` | the tables, sequences, triggers, and the WikiHelp page |
| `wiki_env.sql` | what the wiki needs from the application around it (below) |
| `web_wiki.pkg` | the engine: package `web_wiki` |
| `pages.sql` | starter pages showing links, page forms, a database form, a page script and a lock |
| `read_only.sql` | optional, last: a copy anyone may read and no one may change (with `wiki_read_only` as the DAD's request validation function) -- how sqling.com serves its public one |

## The application around it

The wiki was written inside a larger application, which said who is signed in, how much they
may do, what people are called, and sent mail. Here those are `wiki_env`, over a table of users:

| `wiki_env.` | Returns | Here | In your installation |
|---|---|---|---|
| `current_user` | the user id | a cookie set by `sign_in` | your sign-on |
| `security_level(user)` | 0 none, 1 read, 2 edit, 5 administer | `WIKI_USERS.SECLEVEL` | your roles |
| `contact_name(user)` | "Last, First" | `WIKI_USERS` | your directory |
| `send_mail(from, to, subject, body)` | -- | rows in `WIKI_OUTBOX` | `UTL_SMTP` / `APEX_MAIL` |
| `date_value(text)` | a DATE | ISO or MM/DD/YYYY | your date rules |
| `page_head` | -- | nothing | your validation script |
| `allowed(procedure)` | TRUE for a public entry point | the list below | the gateway's request validation function |

Replace the bodies; `web_wiki` itself does not change. Its entry points are `show_wiki`,
`show_wiki_data`, `saveformdata`, `delete_wiki`, `rename_wiki`, `purge_wiki`, `email_form`,
`email_wiki`, `wiki_js`, `export_page`, `export_data`, `export_wiki`, `export_site` and `embed`; `set_batch_user` is for batch jobs and refuses a web request.
State-changing actions accept only a POST from the same site.

The one other line to look at in `web_wiki.pkg` is `c_base`, the gateway path the wiki builds its
links from: here `owa_util.get_owa_service_path`, the path of the request it is answering. A
gateway that keeps package state between requests may want the path written in as a constant.
