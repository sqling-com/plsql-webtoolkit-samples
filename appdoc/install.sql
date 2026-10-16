-- AppDoc: technical documentation and help, kept by application.
--
-- The application data dictionary Data Design Group, Inc. designed in 2003 to document its
-- web applications -- APP, SCREEN, SCREEN_ITEM, SCREEN_CRUD -- as an application of its own: list the
-- applications, maintain each one's screens, their fields and the tables they touch, and
-- publish two pages from it, the technical reference and the user help.
--
-- The rows come from a harvest (owart.harvest: an application's PL/SQL read for its pages,
-- their parameters and the tables their SQL names) and are then written up by hand here.
-- Export writes an application's rows back out as a script, to keep or load elsewhere.
--
--   bin/run --dad appdoc --install samples/appdoc/install.sql      then  /appdoc/

CREATE TABLE IF NOT EXISTS app (
  app_id             VARCHAR2(15) NOT NULL PRIMARY KEY,
  app_name           VARCHAR2(60) NOT NULL,
  app_description    VARCHAR2(4000),
  app_schema         VARCHAR2(30),
  image_file_prefix  VARCHAR2(80)
);

-- SCREEN as the 2003 dictionary had it, plus SCREEN_GROUP: the section a screen is listed
-- under, which the original kept as table markup in TOC_BEFORE_HTML.
CREATE TABLE IF NOT EXISTS screen (
  screen_id               NUMBER NOT NULL PRIMARY KEY,
  screen_code             VARCHAR2(30),
  app_id                  VARCHAR2(15) NOT NULL,
  screen_description      VARCHAR2(4000),
  source_filename         VARCHAR2(60),
  master_table_name       VARCHAR2(30),
  detail_table_name       VARCHAR2(30),
  display_order           NUMBER(7,2),
  screen_title            VARCHAR2(80),
  image_filename          VARCHAR2(60),
  screen_complex_level    VARCHAR2(10),
  screen_implement_hours  NUMBER(5,2),
  screen_doc_complete     VARCHAR2(1),
  row_sort_order          VARCHAR2(100),
  toc_before_html         VARCHAR2(400),
  toc_after_html          VARCHAR2(400),
  toc_page_number         NUMBER(4),
  screen_help             VARCHAR2(4000),
  screen_user_notes       VARCHAR2(4000),
  screen_group            VARCHAR2(100)
);

CREATE TABLE IF NOT EXISTS screen_item (
  screen_id          NUMBER NOT NULL,
  item_name          VARCHAR2(80) NOT NULL,              -- BLOCK.ITEM for a form
  item_prompt        VARCHAR2(80),
  item_description   VARCHAR2(2000),
  item_table_name    VARCHAR2(30),
  item_column_name   VARCHAR2(30),
  item_max_size      NUMBER(6),
  item_mandatory     VARCHAR2(1),
  item_data_type     VARCHAR2(30),
  item_format_mask   VARCHAR2(30),
  item_display_only  VARCHAR2(1),
  item_default       VARCHAR2(100),
  item_low_value     VARCHAR2(30),
  item_high_value    VARCHAR2(30),
  item_hidden        VARCHAR2(1),
  PRIMARY KEY (screen_id, item_name)
);

-- One row per screen and table (the 2003 table had no key).
CREATE TABLE IF NOT EXISTS screen_crud (
  screen_id       NUMBER NOT NULL,
  table_name      VARCHAR2(30) NOT NULL,
  create_records  VARCHAR2(1),
  read_records    VARCHAR2(1),
  update_records  VARCHAR2(1),
  delete_records  VARCHAR2(1),
  PRIMARY KEY (screen_id, table_name)
);

-- Help macros: one help text for every screen that shows it. {{name}} or {{name:argument}}
-- reads as the macro's Forms text or web text, with $1 the argument; an application's own
-- macro wins over the one for every application (app_id NULL). {{forms:...|web:...}} says it
-- inline. AppDoc's help reads the Forms wording unless asked for the web's (p_ui=web), which
-- is how App Builder's pages ask.
CREATE TABLE IF NOT EXISTS doc_macro (
  app_id      VARCHAR2(15),
  macro_name  VARCHAR2(30) NOT NULL,
  forms_text  VARCHAR2(2000),
  web_text    VARCHAR2(2000)
);

INSERT INTO doc_macro (app_id, macro_name, forms_text, web_text)
SELECT NULL, 'find', 'press <b>Enter Query</b>, type $1, then <b>Execute Query</b>',
       'type $1 in <b>Find</b> and press <b>Find</b>'
  FROM dual WHERE NOT EXISTS (SELECT 1 FROM doc_macro WHERE app_id IS NULL AND macro_name = 'find');
INSERT INTO doc_macro (app_id, macro_name, forms_text, web_text)
SELECT NULL, 'lov', 'the <b>...</b> button (or the List of Values key)', 'the <b>...</b> button (or F9)'
  FROM dual WHERE NOT EXISTS (SELECT 1 FROM doc_macro WHERE app_id IS NULL AND macro_name = 'lov');
INSERT INTO doc_macro (app_id, macro_name, forms_text, web_text)
SELECT NULL, 'help-key', 'the Help key', 'F1 (or <b>Help</b> at the top)'
  FROM dual WHERE NOT EXISTS (SELECT 1 FROM doc_macro WHERE app_id IS NULL AND macro_name = 'help-key');
COMMIT;

CREATE SEQUENCE screen_seq START WITH 10000;

CREATE OR REPLACE PACKAGE appdoc AS
  empty owa.vc_arr;
  PROCEDURE home;
  PROCEDURE app(p_app_id IN VARCHAR2 DEFAULT NULL);
  PROCEDURE app_save(p_app_id IN VARCHAR2, p_app_name IN VARCHAR2, p_app_description IN VARCHAR2 DEFAULT NULL,
                     p_app_schema IN VARCHAR2 DEFAULT NULL, p_image_file_prefix IN VARCHAR2 DEFAULT NULL,
                     p_new IN VARCHAR2 DEFAULT NULL);
  PROCEDURE screen(p_screen_id IN NUMBER DEFAULT NULL, p_app_id IN VARCHAR2 DEFAULT NULL);
  PROCEDURE screen_save(p_screen_id IN NUMBER DEFAULT NULL, p_app_id IN VARCHAR2,
                        p_screen_code IN VARCHAR2, p_screen_title IN VARCHAR2,
                        p_screen_group IN VARCHAR2 DEFAULT NULL, p_display_order IN VARCHAR2 DEFAULT NULL,
                        p_source_filename IN VARCHAR2 DEFAULT NULL, p_master_table_name IN VARCHAR2 DEFAULT NULL,
                        p_screen_description IN VARCHAR2 DEFAULT NULL, p_screen_help IN VARCHAR2 DEFAULT NULL,
                        p_screen_user_notes IN VARCHAR2 DEFAULT NULL);
  PROCEDURE screen_delete(p_screen_id IN NUMBER);
  PROCEDURE item(p_screen_id IN NUMBER, p_item_name IN VARCHAR2 DEFAULT NULL);
  PROCEDURE item_save(p_screen_id IN NUMBER, p_old_name IN VARCHAR2 DEFAULT NULL, p_item_name IN VARCHAR2,
                      p_item_prompt IN VARCHAR2 DEFAULT NULL, p_item_data_type IN VARCHAR2 DEFAULT NULL,
                      p_item_max_size IN VARCHAR2 DEFAULT NULL, p_item_description IN VARCHAR2 DEFAULT NULL,
                      p_item_table_name IN VARCHAR2 DEFAULT NULL, p_item_column_name IN VARCHAR2 DEFAULT NULL,
                      p_item_format_mask IN VARCHAR2 DEFAULT NULL, p_item_default IN VARCHAR2 DEFAULT NULL,
                      p_item_low_value IN VARCHAR2 DEFAULT NULL, p_item_high_value IN VARCHAR2 DEFAULT NULL,
                      p_item_mandatory IN VARCHAR2 DEFAULT NULL, p_item_display_only IN VARCHAR2 DEFAULT NULL,
                      p_item_hidden IN VARCHAR2 DEFAULT NULL);
  PROCEDURE item_delete(p_screen_id IN NUMBER, p_item_name IN VARCHAR2);
  PROCEDURE crud_save(p_screen_id IN NUMBER, p_tables IN owa.vc_arr DEFAULT appdoc.empty,
                      p_c IN owa.vc_arr DEFAULT appdoc.empty, p_r IN owa.vc_arr DEFAULT appdoc.empty,
                      p_u IN owa.vc_arr DEFAULT appdoc.empty, p_d IN owa.vc_arr DEFAULT appdoc.empty,
                      p_new_table IN VARCHAR2 DEFAULT NULL);
  PROCEDURE reference(p_app_id IN VARCHAR2 DEFAULT NULL, p_screen_id IN NUMBER DEFAULT NULL);
  PROCEDURE help(p_app_id IN VARCHAR2 DEFAULT NULL, p_screen_code IN VARCHAR2 DEFAULT NULL, p_ui IN VARCHAR2 DEFAULT 'forms');
  -- Help text with its macros read for a kind of screen: 'forms' or 'web'.
  FUNCTION expand(p_text IN VARCHAR2, p_app_id IN VARCHAR2, p_ui IN VARCHAR2 DEFAULT 'forms') RETURN VARCHAR2;
  PROCEDURE macro_save(p_app_id IN VARCHAR2, p_macro_name IN VARCHAR2, p_forms_text IN VARCHAR2 DEFAULT NULL,
                       p_web_text IN VARCHAR2 DEFAULT NULL);
  PROCEDURE macro_delete(p_app_id IN VARCHAR2, p_macro_name IN VARCHAR2);
  PROCEDURE export(p_app_id IN VARCHAR2);
END appdoc;
/

CREATE OR REPLACE PACKAGE BODY appdoc AS

  -- Row types for APP and SCREEN by way of cursors: inside this package the bare names are
  -- its procedures APPDOC.APP and APPDOC.SCREEN, so app%ROWTYPE would not name the table.
  CURSOR app_row IS SELECT * FROM app;
  CURSOR screen_row IS SELECT * FROM screen;

  -- Text a person typed, put back into a page.
  FUNCTION esc(v IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN htf.escape_sc(v);
  END;

  -- A URL parameter value.
  FUNCTION u(v IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN utl_url.escape(v, TRUE);
  END;

  -- Long identifiers break only after an underscore or a dot.
  FUNCTION brk(v IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN replace(replace(v, '_', '_<wbr>'), '.', '.<wbr>');
  END;

  FUNCTION group_label(g IN VARCHAR2, display_order IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    IF g IS NOT NULL THEN RETURN g; END IF;
    IF display_order IS NULL THEN RETURN 'Other Screens'; END IF;
    RETURN 'Screens';
  END;

  PROCEDURE style IS
  BEGIN
    htp.print('<style>
:root { --ink:#1f2a24; --muted:#66756b; --line:#dde2dd; --soft:#f5f6f4; --card:#fff; --head:#1f3a2c;
        --brand:#24432f; --accent:#2f6b4a; --link:#1d6b46; --tint:#e7eee8; --hl:#fff1bf; }
* { box-sizing: border-box; }
html { scroll-behavior: smooth; scroll-padding-top: 76px; }
body { margin: 0; background: var(--soft); color: var(--ink); font: 15px/1.55 system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
a { color: var(--link); text-decoration: none; } a:hover { text-decoration: underline; }
.top { position: sticky; top: 0; z-index: 5; display: flex; align-items: center; gap: 16px; padding: 12px 24px;
       background: var(--brand); color: #fff; box-shadow: 0 1px 3px rgba(0,0,0,.15); }
.top h1 { margin: 0; font-size: 18px; font-weight: 650; color: #fff; } .top h1 a { color: #fff; }
.top p { margin: 0; font-size: 13px; color: #cfe3d4; }
.top .meta { margin-left: auto; display: flex; align-items: center; gap: 12px; font-size: 13px; color: #cfe3d4; white-space: nowrap; }
.top .meta a { color: #fff; }
.top button { font: inherit; padding: 5px 12px; border: 1px solid rgba(255,255,255,.35); border-radius: 6px; background: transparent; color: #fff; cursor: pointer; }
.top button:hover { background: rgba(255,255,255,.12); }
.crumbs { font-size: 13px; color: #cfe3d4; } .crumbs a { color: #cfe3d4; }
.layout { display: grid; grid-template-columns: 280px minmax(0,1fr); gap: 28px; max-width: 1280px; margin: 0 auto; padding: 24px; }
.single { max-width: 1040px; margin: 0 auto; padding: 24px; }
nav.toc { position: sticky; top: 76px; align-self: start; max-height: calc(100vh - 96px); overflow: auto;
          background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 14px 10px 14px 14px; }
nav.toc input { width: 100%; font: inherit; font-size: 14px; padding: 6px 10px; border: 1px solid #c3cbc4; border-radius: 6px; margin-bottom: 8px; }
nav.toc h4 { margin: 14px 0 4px; font-size: 11px; letter-spacing: .06em; text-transform: uppercase; color: var(--muted); }
nav.toc ul { list-style: none; margin: 0; padding: 0; }
nav.toc li a { display: flex; justify-content: space-between; gap: 8px; padding: 3px 6px; border-radius: 5px; color: var(--ink); font-size: 14px; }
nav.toc li a:hover { background: var(--tint); text-decoration: none; }
nav.toc li a span { color: var(--muted); font: 11px/1.9 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
main { min-width: 0; }
section.card, section.screen { background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 20px 24px; margin-bottom: 22px; }
section.screen:target { box-shadow: 0 0 0 3px var(--hl); }
.card > header, .screen > header { display: flex; flex-wrap: wrap; align-items: baseline; gap: 10px; border-bottom: 1px solid var(--line); padding-bottom: 10px; margin-bottom: 12px; }
h2 { margin: 0; font-size: 20px; font-weight: 650; color: var(--head); }
.code { font: 12px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; background: var(--tint); color: var(--head); padding: 2px 7px; border-radius: 5px; }
.grp, .right { margin-left: auto; font-size: 12px; color: var(--muted); }
.desc { margin: 0 0 14px; }
.shot { max-width: 100%; border: 1px solid var(--line); border-radius: 6px; margin: 4px 0 14px; }
h3 { margin: 18px 0 8px; font-size: 13px; letter-spacing: .05em; text-transform: uppercase; color: var(--muted); font-weight: 650; }
.scroll { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; font-size: 13.5px; }
th { text-align: left; background: var(--tint); color: var(--head); font-weight: 600; padding: 6px 10px; border-bottom: 1px solid var(--line); white-space: nowrap; }
td { padding: 6px 10px; border-bottom: 1px solid var(--line); vertical-align: top; }
tbody tr:nth-child(even) td { background: #fafbfa; }
table.crud { width: auto; min-width: 420px; }
table.crud th.c, table.crud td.c { text-align: center; width: 70px; }
td.yes { color: var(--accent); font-weight: 700; } td.no { color: #b9c2bb; }
td.mono, .mono { font: 12.5px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
td.type { white-space: nowrap; } table.fields { min-width: 760px; } td.num { text-align: right; }
table.list { table-layout: fixed; min-width: 640px; } table.list col.o { width: 70px; } table.list col.c { width: 170px; }
table.list col.n { width: 80px; } table.list col.s { width: 230px; } table.list th.num { text-align: right; }
.chip { display: inline-block; margin: 0 4px 3px 0; padding: 1px 7px; border-radius: 999px; font-size: 11.5px; background: #eef1ee; color: #3d4d43; white-space: nowrap; }
.chip.req { background: #fde8e4; color: #8a2c1c; } .chip.ro { background: #e8eef8; color: #2b4a7a; } .chip.hid { background: #efeaf6; color: #563f7a; }
.chip.warn { background: #fff1bf; color: #6b5310; }
details { margin-top: 16px; border: 1px solid var(--line); border-radius: 8px; padding: 8px 14px; background: #fbfcfb; }
details summary { cursor: pointer; font-weight: 600; color: var(--head); }
.help { font-size: 15.5px; } .help p { margin: 0 0 12px; }
.empty { color: var(--muted); font-style: italic; }
.foot { text-align: center; color: var(--muted); font-size: 12px; padding: 8px 0 28px; }
.actions { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin-top: 16px; }
.btn { display: inline-block; padding: 6px 14px; border-radius: 6px; border: 1px solid var(--accent); color: var(--accent); background: #fff; font: inherit; font-size: 14px; cursor: pointer; }
.btn:hover { background: var(--tint); text-decoration: none; }
.btn.primary { background: var(--accent); color: #fff; } .btn.primary:hover { background: #24543a; }
.btn.danger { border-color: #b4412e; color: #b4412e; } .btn.danger:hover { background: #fde8e4; }
.btn.small { padding: 2px 9px; font-size: 13px; }
form.grid { display: grid; grid-template-columns: 180px minmax(0,1fr); gap: 10px 16px; align-items: start; }
form.grid label { padding-top: 7px; font-size: 14px; font-weight: 600; color: var(--head); }
form.grid .hint { grid-column: 2; margin-top: -6px; font-size: 12.5px; color: var(--muted); }
form.grid .actions { grid-column: 2; margin-top: 4px; }
input[type=text], input[type=number], textarea, select { width: 100%; font: inherit; font-size: 14px; padding: 6px 10px; border: 1px solid #c3cbc4; border-radius: 6px; background: #fff; color: var(--ink); }
textarea { min-height: 110px; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 13px; }
input.short { max-width: 200px; } input.tiny { max-width: 110px; }
.checks { display: flex; flex-wrap: wrap; gap: 16px; padding-top: 7px; font-size: 14px; } .checks input { margin-right: 5px; }
.stats { display: flex; gap: 10px; flex-wrap: wrap; }
.notice { background: #e9f4ec; border: 1px solid #c6e0cd; color: #1f4a30; border-radius: 8px; padding: 8px 14px; margin-bottom: 18px; font-size: 14px; }
@media (max-width: 860px) { .layout { grid-template-columns: 1fr; padding: 16px; } .single { padding: 16px; } nav.toc { position: static; max-height: none; }
  form.grid { grid-template-columns: 1fr; } form.grid .hint, form.grid .actions { grid-column: 1; } .top .meta span { display: none; } }
@media print {
  body { background: #fff; font-size: 11pt; } .top { position: static; box-shadow: none; background: #fff; color: #000; border-bottom: 2px solid #000; }
  .top h1, .top h1 a, .top p, .top .meta { color: #000; } .top button, nav.toc input, .crumbs { display: none; }
  .layout { display: block; padding: 0; max-width: none; } nav.toc { position: static; border: 0; max-height: none; page-break-after: always; }
  section.screen { border: 0; border-radius: 0; padding: 0; page-break-before: always; } details { border: 0; padding: 0; } details > summary { display: none; }
  tbody tr:nth-child(even) td { background: none; } a { color: #000; }
}
</style>');
  END;

  PROCEDURE page_open(title IN VARCHAR2, heading IN VARCHAR2 DEFAULT NULL, crumbs IN VARCHAR2 DEFAULT NULL,
                      meta IN VARCHAR2 DEFAULT NULL, sub IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    htp.print('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">');
    htp.print('<meta name="viewport" content="width=device-width, initial-scale=1">');
    htp.print('<title>' || esc(title) || '</title>');
    style;
    htp.print('</head><body><header class="top"><div>');
    IF crumbs IS NOT NULL THEN htp.print('<div class="crumbs">' || crumbs || '</div>'); END IF;
    htp.print('<h1>' || nvl(heading, esc(title)) || '</h1>');
    IF sub IS NOT NULL THEN htp.print('<p>' || sub || '</p>'); END IF;
    htp.print('</div><div class="meta">' || meta || '</div></header>');
  END;

  PROCEDURE page_close IS
  BEGIN
    htp.print('</body></html>');
  END;

  PROCEDURE mark(v IN VARCHAR2) IS
  BEGIN
    IF v = 'Y' THEN htp.prn('<td class="c yes" title="Yes">&#10003;</td>');
    ELSE htp.prn('<td class="c no">&middot;</td>'); END IF;
  END;

  FUNCTION chip(label IN VARCHAR2, cls IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
  BEGIN
    RETURN '<span class="chip' || CASE WHEN cls IS NOT NULL THEN ' ' || cls END || '">' || label || '</span>';
  END;

  PROCEDURE field(label IN VARCHAR2, name IN VARCHAR2, value IN VARCHAR2, cls IN VARCHAR2 DEFAULT NULL,
                  hint IN VARCHAR2 DEFAULT NULL, required IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    htp.print('<label for="' || name || '">' || label || '</label><input type="text" id="' || name || '" name="' || name
              || '" value="' || esc(value) || '"' || CASE WHEN cls IS NOT NULL THEN ' class="' || cls || '"' END
              || CASE WHEN required THEN ' required' END || '>');
    IF hint IS NOT NULL THEN htp.print('<div class="hint">' || hint || '</div>'); END IF;
  END;

  PROCEDURE area(label IN VARCHAR2, name IN VARCHAR2, value IN VARCHAR2, hint IN VARCHAR2 DEFAULT NULL,
                 rows_n IN NUMBER DEFAULT 6) IS
  BEGIN
    htp.print('<label for="' || name || '">' || label || '</label><textarea id="' || name || '" name="' || name
              || '" rows="' || rows_n || '">' || esc(value) || '</textarea>');
    IF hint IS NOT NULL THEN htp.print('<div class="hint">' || hint || '</div>'); END IF;
  END;

  FUNCTION yn(v IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN upper(v) IN ('Y', 'YES', 'ON', 'TRUE') THEN 'Y' END;
  END;

  -- MACROS ---------------------------------------------------------------------------------
  FUNCTION expand(p_text IN VARCHAR2, p_app_id IN VARCHAR2, p_ui IN VARCHAR2 DEFAULT 'forms') RETURN VARCHAR2 IS
    t VARCHAR2(32767) := p_text; out VARCHAR2(32767); pos PLS_INTEGER := 1; s PLS_INTEGER; e PLS_INTEGER;
    body VARCHAR2(4000); part VARCHAR2(4000); rest VARCHAR2(4000); name VARCHAR2(100); arg VARCHAR2(4000);
    rep VARCHAR2(4000); ui VARCHAR2(10) := lower(coalesce(p_ui, 'forms')); found BOOLEAN; bar PLS_INTEGER;
  BEGIN
    IF t IS NULL OR instr(t, '{{') = 0 THEN RETURN t; END IF;
    LOOP
      s := instr(t, '{{', pos);
      EXIT WHEN s = 0;
      e := instr(t, '}}', s + 2);
      EXIT WHEN e = 0;
      body := substr(t, s + 2, e - s - 2);
      IF regexp_like(body, '^(forms|web):') THEN
        -- {{forms:...|web:...}}: the part for this screen, nothing if it has none
        rep := NULL; rest := body;
        LOOP
          bar := instr(rest, '|');
          part := CASE WHEN bar > 0 THEN substr(rest, 1, bar - 1) ELSE rest END;
          IF lower(part) LIKE ui || ':%' THEN rep := substr(part, length(ui) + 2); END IF;
          EXIT WHEN bar = 0;
          rest := substr(rest, bar + 1);
        END LOOP;
      ELSE
        name := lower(trim(CASE WHEN instr(body, ':') > 0 THEN substr(body, 1, instr(body, ':') - 1) ELSE body END));
        arg := CASE WHEN instr(body, ':') > 0 THEN substr(body, instr(body, ':') + 1) END;
        found := FALSE;
        FOR m IN (SELECT forms_text, web_text FROM doc_macro
                   WHERE macro_name = name AND (app_id = upper(p_app_id) OR app_id IS NULL)
                   ORDER BY CASE WHEN app_id IS NULL THEN 1 ELSE 0 END) LOOP
          rep := replace(CASE WHEN ui = 'web' THEN coalesce(m.web_text, m.forms_text) ELSE m.forms_text END, '$1', arg);
          found := TRUE;
          EXIT;
        END LOOP;
        IF NOT found THEN rep := '{{' || body || '}}'; END IF;      -- unknown: left for its author to see
      END IF;
      out := out || substr(t, pos, s - pos) || rep;
      pos := e + 2;
    END LOOP;
    RETURN out || substr(t, pos);
  END;

  PROCEDURE macro_save(p_app_id IN VARCHAR2, p_macro_name IN VARCHAR2, p_forms_text IN VARCHAR2 DEFAULT NULL,
                       p_web_text IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    DELETE FROM doc_macro WHERE app_id = upper(p_app_id) AND macro_name = lower(trim(p_macro_name));
    INSERT INTO doc_macro (app_id, macro_name, forms_text, web_text)
    VALUES (upper(p_app_id), lower(trim(p_macro_name)), p_forms_text, p_web_text);
    COMMIT;
    owa_util.redirect_url('appdoc.app?p_app_id=' || u(p_app_id) || '#macros');
  END;

  PROCEDURE macro_delete(p_app_id IN VARCHAR2, p_macro_name IN VARCHAR2) IS
  BEGIN
    DELETE FROM doc_macro WHERE app_id = upper(p_app_id) AND macro_name = lower(p_macro_name);
    COMMIT;
    owa_util.redirect_url('appdoc.app?p_app_id=' || u(p_app_id) || '#macros');
  END;

  -- HOME -----------------------------------------------------------------------------------
  PROCEDURE home IS
    n NUMBER := 0;
  BEGIN
    page_open('AppDoc', 'AppDoc', NULL, NULL, 'Technical documentation and help, kept by application');
    htp.print('<div class="single">');
    FOR a IN (SELECT a.*, (SELECT count(*) FROM screen s WHERE s.app_id = a.app_id) screens,
                     (SELECT count(*) FROM screen s WHERE s.app_id = a.app_id AND s.screen_description IS NULL) undescribed,
                     (SELECT count(*) FROM screen_item i, screen s WHERE s.app_id = a.app_id AND i.screen_id = s.screen_id) items
                FROM app a ORDER BY a.app_name) LOOP
      n := n + 1;
      htp.print('<section class="card"><header><h2><a href="appdoc.app?p_app_id=' || u(a.app_id) || '">' || esc(a.app_name)
                || '</a></h2><span class="code">' || esc(a.app_id) || '</span></header>');
      IF a.app_description IS NOT NULL THEN htp.print('<p class="desc">' || esc(a.app_description) || '</p>'); END IF;
      htp.print('<div class="stats">' || chip(a.screens || ' screens') || chip(a.items || ' fields')
                || CASE WHEN a.undescribed > 0 THEN chip(a.undescribed || ' without a description', 'warn') END || '</div>');
      htp.print('<div class="actions"><a class="btn primary" href="appdoc.app?p_app_id=' || u(a.app_id) || '">Maintain</a>'
                || '<a class="btn" target="_blank" href="appdoc.reference?p_app_id=' || u(a.app_id) || '">Technical reference</a>'
                || '<a class="btn" target="_blank" href="appdoc.help?p_app_id=' || u(a.app_id) || '">Help</a></div></section>');
    END LOOP;
    IF n = 0 THEN htp.print('<section class="card"><p class="empty">No applications yet.</p></section>'); END IF;
    htp.print('<section class="card"><header><h2>New application</h2></header>'
              || '<form class="grid" method="post" action="appdoc.app_save"><input type="hidden" name="p_new" value="Y">');
    field('Application ID', 'p_app_id', NULL, 'short', 'Short and unique, e.g. HE. It cannot be changed later.', TRUE);
    field('Name', 'p_app_name', NULL, NULL, NULL, TRUE);
    area('Description', 'p_app_description', NULL, NULL, 3);
    field('Schema', 'p_app_schema', NULL, 'short', 'Where the application''s tables live.');
    htp.print('<div class="actions"><button class="btn primary" type="submit">Create</button></div></form></section>');
    htp.print('<p class="foot">Screens, fields and table access are harvested from an application''s source; '
              || 'descriptions and help are written here.</p></div>');
    page_close;
  END;

  -- APPLICATION ----------------------------------------------------------------------------
  PROCEDURE app(p_app_id IN VARCHAR2 DEFAULT NULL) IS
    r      app_row%ROWTYPE;
    grp    VARCHAR2(200) := '#';
    open_t BOOLEAN := FALSE;
  BEGIN
    SELECT * INTO r FROM app WHERE app_id = p_app_id;
    page_open(r.app_name || ' - AppDoc', esc(r.app_name), '<a href="appdoc.home">AppDoc</a>',
              '<a href="appdoc.reference?p_app_id=' || u(r.app_id) || '" target="_blank">Technical reference</a>'
              || '<a href="appdoc.help?p_app_id=' || u(r.app_id) || '" target="_blank">Help</a>'
              || '<a href="appdoc.export?p_app_id=' || u(r.app_id) || '">Export</a>');
    htp.print('<div class="single">');
    htp.print('<section class="card"><header><h2>Screens</h2><span class="right"><a class="btn small primary" href="appdoc.screen?p_app_id='
              || u(r.app_id) || '">New screen</a></span></header>');
    FOR s IN (SELECT s.*, (SELECT count(*) FROM screen_item i WHERE i.screen_id = s.screen_id) items,
                     (SELECT count(*) FROM screen_crud c WHERE c.screen_id = s.screen_id) tabs
                FROM screen s WHERE s.app_id = r.app_id
               ORDER BY CASE WHEN s.display_order IS NULL THEN 1 ELSE 0 END, s.display_order, s.screen_title) LOOP
      IF group_label(s.screen_group, s.display_order) <> grp THEN
        IF open_t THEN htp.print('</tbody></table></div>'); END IF;
        grp := group_label(s.screen_group, s.display_order);
        htp.print('<h3>' || esc(grp) || '</h3><div class="scroll"><table class="list"><colgroup><col class="o"><col><col class="c">'
                  || '<col class="n"><col class="n"><col class="s"></colgroup><thead><tr><th class="num">Order</th><th>Screen</th><th>Code</th>'
                  || '<th class="num">Fields</th><th class="num">Tables</th><th>Status</th></tr></thead><tbody>');
        open_t := TRUE;
      END IF;
      htp.print('<tr><td class="num">' || s.display_order || '</td><td><a href="appdoc.screen?p_screen_id=' || s.screen_id || '">'
                || esc(nvl(s.screen_title, s.screen_code)) || '</a></td><td class="mono">' || brk(esc(s.screen_code))
                || '</td><td class="num">' || s.items || '</td><td class="num">' || s.tabs || '</td><td>'
                || CASE WHEN s.screen_description IS NULL THEN chip('No description', 'warn') END
                || CASE WHEN s.screen_help IS NULL THEN chip('No help', 'warn') END || '</td></tr>');
    END LOOP;
    IF open_t THEN htp.print('</tbody></table></div>'); ELSE htp.print('<p class="empty">No screens yet.</p>'); END IF;
    htp.print('</section>');

    -- the help macros this application's text can use
    htp.print('<section class="card" id="macros"><header><h2>Help macros</h2><span class="right">'
              || 'In help and descriptions: <span class="code">{{name}}</span> or <span class="code">{{name:argument}}</span> '
              || '($1 in the text), or <span class="code">{{forms:...|web:...}}</span></span></header>'
              || '<div class="scroll"><table><thead><tr><th>Macro</th><th>Oracle Forms</th><th>Web (App Builder)</th><th></th></tr></thead><tbody>');
    FOR m IN (SELECT app_id, macro_name, forms_text, web_text FROM doc_macro
               WHERE app_id = r.app_id OR (app_id IS NULL AND NOT EXISTS
                     (SELECT 1 FROM doc_macro o WHERE o.app_id = r.app_id AND o.macro_name = doc_macro.macro_name))
               ORDER BY macro_name) LOOP
      htp.print('<tr><td class="mono">{{' || esc(m.macro_name) || '}}</td><td>' || esc(m.forms_text) || '</td><td>' || esc(m.web_text)
                || '</td><td>' || CASE WHEN m.app_id IS NULL THEN chip('every application')
                ELSE '<form method="post" action="appdoc.macro_delete" style="display:inline"><input type="hidden" name="p_app_id" value="'
                     || esc(r.app_id) || '"><input type="hidden" name="p_macro_name" value="' || esc(m.macro_name)
                     || '"><button class="btn small danger" type="submit">Delete</button></form>' END || '</td></tr>');
    END LOOP;
    htp.print('</tbody></table></div><form class="grid" method="post" action="appdoc.macro_save" style="margin-top:14px">'
              || '<input type="hidden" name="p_app_id" value="' || esc(r.app_id) || '">');
    field('Macro', 'p_macro_name', NULL, 'short', 'A new name, or one above to replace it for this application.', TRUE);
    field('Oracle Forms text', 'p_forms_text', NULL);
    field('Web text', 'p_web_text', NULL);
    htp.print('<div class="actions"><button class="btn" type="submit">Save macro</button></div></form></section>');

    htp.print('<section class="card"><header><h2>Application</h2><span class="code">' || esc(r.app_id) || '</span></header>'
              || '<form class="grid" method="post" action="appdoc.app_save"><input type="hidden" name="p_app_id" value="' || esc(r.app_id) || '">');
    field('Name', 'p_app_name', r.app_name, NULL, NULL, TRUE);
    area('Description', 'p_app_description', r.app_description, NULL, 3);
    field('Schema', 'p_app_schema', r.app_schema, 'short');
    field('Screenshot location', 'p_image_file_prefix', r.image_file_prefix, NULL,
          'A URL each screen''s image file name is added to. Empty: no screenshots.');
    htp.print('<div class="actions"><button class="btn primary" type="submit">Save</button></div></form></section></div>');
    page_close;
  EXCEPTION WHEN no_data_found THEN
    owa_util.redirect_url('appdoc.home');
  END;

  PROCEDURE app_save(p_app_id IN VARCHAR2, p_app_name IN VARCHAR2, p_app_description IN VARCHAR2 DEFAULT NULL,
                     p_app_schema IN VARCHAR2 DEFAULT NULL, p_image_file_prefix IN VARCHAR2 DEFAULT NULL,
                     p_new IN VARCHAR2 DEFAULT NULL) IS
    id VARCHAR2(15) := upper(trim(p_app_id));
  BEGIN
    IF p_new = 'Y' THEN
      INSERT INTO app (app_id, app_name, app_description, app_schema, image_file_prefix)
      VALUES (id, trim(p_app_name), p_app_description, upper(trim(p_app_schema)), trim(p_image_file_prefix));
    ELSE
      UPDATE app SET app_name = trim(p_app_name), app_description = p_app_description,
                     app_schema = upper(trim(p_app_schema)), image_file_prefix = trim(p_image_file_prefix)
       WHERE app_id = id;
    END IF;
    COMMIT;
    owa_util.redirect_url('appdoc.app?p_app_id=' || u(id));
  END;

  -- SCREEN ---------------------------------------------------------------------------------
  PROCEDURE screen(p_screen_id IN NUMBER DEFAULT NULL, p_app_id IN VARCHAR2 DEFAULT NULL) IS
    s     screen_row%ROWTYPE;
    a     app_row%ROWTYPE;
    n     NUMBER := 0;
  BEGIN
    IF p_screen_id IS NOT NULL THEN
      SELECT * INTO s FROM screen WHERE screen_id = p_screen_id;
    ELSE
      s.app_id := upper(p_app_id);
    END IF;
    SELECT * INTO a FROM app WHERE app_id = s.app_id;
    page_open(nvl(s.screen_title, 'New screen') || ' - ' || a.app_name,
              CASE WHEN p_screen_id IS NULL THEN 'New screen' ELSE esc(nvl(s.screen_title, s.screen_code)) END,
              '<a href="appdoc.home">AppDoc</a> / <a href="appdoc.app?p_app_id=' || u(a.app_id) || '">' || esc(a.app_name) || '</a>',
              CASE WHEN p_screen_id IS NOT NULL THEN
                '<a target="_blank" href="appdoc.reference?p_app_id=' || u(a.app_id) || '&p_screen_id=' || s.screen_id || '">Reference</a>'
                || '<a target="_blank" href="appdoc.help?p_app_id=' || u(a.app_id) || '&p_screen_code=' || u(s.screen_code) || '">Help</a>' END);
    htp.print('<div class="single"><section class="card"><header><h2>Screen</h2>'
              || CASE WHEN s.screen_code IS NOT NULL THEN '<span class="code">' || esc(s.screen_code) || '</span>' END || '</header>');
    htp.print('<form class="grid" method="post" action="appdoc.screen_save">'
              || '<input type="hidden" name="p_screen_id" value="' || s.screen_id || '">'
              || '<input type="hidden" name="p_app_id" value="' || esc(a.app_id) || '">');
    field('Code', 'p_screen_code', s.screen_code, 'short', 'The procedure or form that draws the screen.', TRUE);
    field('Title', 'p_screen_title', s.screen_title, NULL, NULL, TRUE);
    htp.print('<label for="p_screen_group">Section</label><input type="text" id="p_screen_group" name="p_screen_group" list="groups" value="'
              || esc(s.screen_group) || '"><datalist id="groups">');
    FOR g IN (SELECT DISTINCT screen_group FROM screen WHERE app_id = a.app_id AND screen_group IS NOT NULL ORDER BY 1) LOOP
      htp.print('<option value="' || esc(g.screen_group) || '">');
    END LOOP;
    htp.print('</datalist><div class="hint">The heading the screen is listed under.</div>');
    field('Order', 'p_display_order', s.display_order, 'tiny', 'Position in the contents; empty lists it last.');
    field('Source file', 'p_source_filename', s.source_filename, 'short');
    field('Main table', 'p_master_table_name', s.master_table_name, 'short');
    area('Description', 'p_screen_description', s.screen_description, 'For the technical reference. HTML is allowed.', 5);
    area('Help', 'p_screen_help', s.screen_help, 'What a user of the screen reads. HTML is allowed, and the application''s '
         || '<a href="appdoc.app?p_app_id=' || u(s.app_id) || '#macros">help macros</a>: one text for Oracle Forms and the web.', 10);
    area('Team notes', 'p_screen_user_notes', s.screen_user_notes, 'Internal; not published.', 3);
    htp.print('<div class="actions"><button class="btn primary" type="submit">Save</button></div></form>');
    IF p_screen_id IS NOT NULL THEN
      htp.print('<form method="post" action="appdoc.screen_delete" onsubmit="return confirm(''Delete this screen, its fields and its table access?'')">'
                || '<input type="hidden" name="p_screen_id" value="' || s.screen_id || '">'
                || '<div class="actions"><button class="btn danger small" type="submit">Delete screen</button></div></form>');
    END IF;
    htp.print('</section>');

    IF p_screen_id IS NOT NULL THEN
      -- Fields
      htp.print('<section class="card"><header><h2>Fields</h2><span class="right"><a class="btn small primary" href="appdoc.item?p_screen_id='
                || s.screen_id || '">New field</a></span></header>');
      FOR i IN (SELECT * FROM screen_item WHERE screen_id = s.screen_id ORDER BY item_name) LOOP
        n := n + 1;
        IF n = 1 THEN
          htp.print('<div class="scroll"><table class="fields"><thead><tr><th>Item</th><th>Prompt</th><th>Type</th><th>Rules</th>'
                    || '<th>Description</th><th>Maps to</th></tr></thead><tbody>');
        END IF;
        htp.print('<tr><td class="mono"><a href="appdoc.item?p_screen_id=' || s.screen_id || '&p_item_name=' || u(i.item_name) || '">'
                  || brk(esc(i.item_name)) || '</a></td><td>' || esc(i.item_prompt) || '</td><td class="mono type">' || esc(i.item_data_type)
                  || CASE WHEN i.item_max_size IS NOT NULL THEN '(' || i.item_max_size || ')' END || '</td><td>'
                  || CASE WHEN i.item_mandatory = 'Y' THEN chip('Required', 'req') END
                  || CASE WHEN i.item_display_only = 'Y' THEN chip('Display only', 'ro') END
                  || CASE WHEN i.item_hidden = 'Y' THEN chip('Hidden', 'hid') END
                  || CASE WHEN i.item_format_mask IS NOT NULL THEN chip('Format ' || esc(i.item_format_mask)) END
                  || '</td><td>' || CASE WHEN i.item_description IS NULL THEN chip('No description', 'warn') ELSE i.item_description END
                  || '</td><td class="mono">' || brk(esc(i.item_table_name || CASE WHEN i.item_column_name IS NOT NULL THEN '.' || i.item_column_name END))
                  || '</td></tr>');
      END LOOP;
      IF n > 0 THEN htp.print('</tbody></table></div>'); ELSE htp.print('<p class="empty">No fields yet.</p>'); END IF;
      htp.print('</section>');

      -- Table access
      htp.print('<section class="card"><header><h2>Table access</h2></header><form method="post" action="appdoc.crud_save">'
                || '<input type="hidden" name="p_screen_id" value="' || s.screen_id || '">');
      n := 0;
      FOR c IN (SELECT * FROM screen_crud WHERE screen_id = s.screen_id ORDER BY table_name) LOOP
        n := n + 1;
        IF n = 1 THEN
          htp.print('<div class="scroll"><table class="crud"><thead><tr><th>Table</th><th class="c">Create</th><th class="c">Read</th>'
                    || '<th class="c">Update</th><th class="c">Delete</th></tr></thead><tbody>');
        END IF;
        htp.print('<tr><td class="mono">' || brk(esc(c.table_name)) || '<input type="hidden" name="p_tables" value="' || esc(c.table_name) || '"></td>');
        htp.print('<td class="c"><input type="checkbox" name="p_c" value="' || esc(c.table_name) || '"' || CASE WHEN c.create_records = 'Y' THEN ' checked' END || '></td>'
                  || '<td class="c"><input type="checkbox" name="p_r" value="' || esc(c.table_name) || '"' || CASE WHEN c.read_records = 'Y' THEN ' checked' END || '></td>'
                  || '<td class="c"><input type="checkbox" name="p_u" value="' || esc(c.table_name) || '"' || CASE WHEN c.update_records = 'Y' THEN ' checked' END || '></td>'
                  || '<td class="c"><input type="checkbox" name="p_d" value="' || esc(c.table_name) || '"' || CASE WHEN c.delete_records = 'Y' THEN ' checked' END || '></td></tr>');
      END LOOP;
      IF n > 0 THEN htp.print('</tbody></table></div>'); END IF;
      htp.print('<div class="actions"><input type="text" name="p_new_table" class="short" placeholder="Add a table"'
                || ' aria-label="Add a table"><button class="btn primary" type="submit">Save table access</button>'
                || '<span class="right">A table with nothing ticked is removed.</span></div></form></section>');
    END IF;
    htp.print('</div>');
    page_close;
  EXCEPTION WHEN no_data_found THEN
    owa_util.redirect_url('appdoc.home');
  END;

  PROCEDURE screen_save(p_screen_id IN NUMBER DEFAULT NULL, p_app_id IN VARCHAR2,
                        p_screen_code IN VARCHAR2, p_screen_title IN VARCHAR2,
                        p_screen_group IN VARCHAR2 DEFAULT NULL, p_display_order IN VARCHAR2 DEFAULT NULL,
                        p_source_filename IN VARCHAR2 DEFAULT NULL, p_master_table_name IN VARCHAR2 DEFAULT NULL,
                        p_screen_description IN VARCHAR2 DEFAULT NULL, p_screen_help IN VARCHAR2 DEFAULT NULL,
                        p_screen_user_notes IN VARCHAR2 DEFAULT NULL) IS
    id NUMBER := p_screen_id;
  BEGIN
    IF id IS NULL THEN
      SELECT screen_seq.NEXTVAL INTO id FROM dual;
      INSERT INTO screen (screen_id, app_id) VALUES (id, upper(p_app_id));
    END IF;
    UPDATE screen SET screen_code = upper(trim(p_screen_code)), screen_title = trim(p_screen_title),
                      screen_group = trim(p_screen_group), display_order = to_number(trim(p_display_order)),
                      source_filename = trim(p_source_filename), master_table_name = upper(trim(p_master_table_name)),
                      screen_description = p_screen_description, screen_help = p_screen_help,
                      screen_user_notes = p_screen_user_notes
     WHERE screen_id = id;
    COMMIT;
    owa_util.redirect_url('appdoc.screen?p_screen_id=' || id);
  END;

  PROCEDURE screen_delete(p_screen_id IN NUMBER) IS
    a VARCHAR2(15);
  BEGIN
    SELECT app_id INTO a FROM screen WHERE screen_id = p_screen_id;
    DELETE FROM screen_item WHERE screen_id = p_screen_id;
    DELETE FROM screen_crud WHERE screen_id = p_screen_id;
    DELETE FROM screen WHERE screen_id = p_screen_id;
    COMMIT;
    owa_util.redirect_url('appdoc.app?p_app_id=' || u(a));
  END;

  -- FIELD ----------------------------------------------------------------------------------
  PROCEDURE item(p_screen_id IN NUMBER, p_item_name IN VARCHAR2 DEFAULT NULL) IS
    s screen_row%ROWTYPE;
    i screen_item%ROWTYPE;
    a app_row%ROWTYPE;
  BEGIN
    SELECT * INTO s FROM screen WHERE screen_id = p_screen_id;
    SELECT * INTO a FROM app WHERE app_id = s.app_id;
    IF p_item_name IS NOT NULL THEN
      SELECT * INTO i FROM screen_item WHERE screen_id = p_screen_id AND item_name = p_item_name;
    END IF;
    page_open(nvl(p_item_name, 'New field') || ' - ' || s.screen_title, esc(nvl(p_item_name, 'New field')),
              '<a href="appdoc.home">AppDoc</a> / <a href="appdoc.app?p_app_id=' || u(a.app_id) || '">' || esc(a.app_name)
              || '</a> / <a href="appdoc.screen?p_screen_id=' || s.screen_id || '">' || esc(nvl(s.screen_title, s.screen_code)) || '</a>');
    htp.print('<div class="single"><section class="card"><header><h2>Field</h2></header>'
              || '<form class="grid" method="post" action="appdoc.item_save">'
              || '<input type="hidden" name="p_screen_id" value="' || s.screen_id || '">'
              || '<input type="hidden" name="p_old_name" value="' || esc(p_item_name) || '">');
    field('Item name', 'p_item_name', i.item_name, 'short', 'The parameter or item the screen uses.', TRUE);
    field('Prompt', 'p_item_prompt', i.item_prompt);
    field('Data type', 'p_item_data_type', i.item_data_type, 'short', 'CHAR, NUMBER, DATE, BUTTON, LINK ...');
    field('Maximum size', 'p_item_max_size', i.item_max_size, 'tiny');
    area('Description', 'p_item_description', i.item_description, NULL, 3);
    field('Table', 'p_item_table_name', i.item_table_name, 'short');
    field('Column', 'p_item_column_name', i.item_column_name, 'short');
    field('Format', 'p_item_format_mask', i.item_format_mask, 'short');
    field('Default', 'p_item_default', i.item_default, 'short');
    field('Lowest value', 'p_item_low_value', i.item_low_value, 'short');
    field('Highest value', 'p_item_high_value', i.item_high_value, 'short');
    htp.print('<label>Rules</label><div class="checks">'
              || '<label><input type="checkbox" name="p_item_mandatory" value="Y"' || CASE WHEN i.item_mandatory = 'Y' THEN ' checked' END || '>Required</label>'
              || '<label><input type="checkbox" name="p_item_display_only" value="Y"' || CASE WHEN i.item_display_only = 'Y' THEN ' checked' END || '>Display only</label>'
              || '<label><input type="checkbox" name="p_item_hidden" value="Y"' || CASE WHEN i.item_hidden = 'Y' THEN ' checked' END || '>Hidden</label></div>');
    htp.print('<div class="actions"><button class="btn primary" type="submit">Save</button>'
              || '<a class="btn" href="appdoc.screen?p_screen_id=' || s.screen_id || '">Back to the screen</a></div></form>');
    IF p_item_name IS NOT NULL THEN
      htp.print('<form method="post" action="appdoc.item_delete" onsubmit="return confirm(''Delete this field?'')">'
                || '<input type="hidden" name="p_screen_id" value="' || s.screen_id || '">'
                || '<input type="hidden" name="p_item_name" value="' || esc(p_item_name) || '">'
                || '<div class="actions"><button class="btn danger small" type="submit">Delete field</button></div></form>');
    END IF;
    htp.print('</section></div>');
    page_close;
  EXCEPTION WHEN no_data_found THEN
    owa_util.redirect_url('appdoc.screen?p_screen_id=' || p_screen_id);
  END;

  PROCEDURE item_save(p_screen_id IN NUMBER, p_old_name IN VARCHAR2 DEFAULT NULL, p_item_name IN VARCHAR2,
                      p_item_prompt IN VARCHAR2 DEFAULT NULL, p_item_data_type IN VARCHAR2 DEFAULT NULL,
                      p_item_max_size IN VARCHAR2 DEFAULT NULL, p_item_description IN VARCHAR2 DEFAULT NULL,
                      p_item_table_name IN VARCHAR2 DEFAULT NULL, p_item_column_name IN VARCHAR2 DEFAULT NULL,
                      p_item_format_mask IN VARCHAR2 DEFAULT NULL, p_item_default IN VARCHAR2 DEFAULT NULL,
                      p_item_low_value IN VARCHAR2 DEFAULT NULL, p_item_high_value IN VARCHAR2 DEFAULT NULL,
                      p_item_mandatory IN VARCHAR2 DEFAULT NULL, p_item_display_only IN VARCHAR2 DEFAULT NULL,
                      p_item_hidden IN VARCHAR2 DEFAULT NULL) IS
    nm VARCHAR2(80) := upper(trim(p_item_name));
    -- Worked out first: a package's private functions cannot be called from its SQL.
    v_mandatory    VARCHAR2(1) := yn(p_item_mandatory);
    v_display_only VARCHAR2(1) := yn(p_item_display_only);
    v_hidden       VARCHAR2(1) := yn(p_item_hidden);
  BEGIN
    IF p_old_name IS NULL THEN
      INSERT INTO screen_item (screen_id, item_name) VALUES (p_screen_id, nm);
    ELSIF p_old_name <> nm THEN
      UPDATE screen_item SET item_name = nm WHERE screen_id = p_screen_id AND item_name = p_old_name;
    END IF;
    UPDATE screen_item SET item_prompt = trim(p_item_prompt), item_data_type = upper(trim(p_item_data_type)),
                           item_max_size = to_number(trim(p_item_max_size)), item_description = p_item_description,
                           item_table_name = upper(trim(p_item_table_name)), item_column_name = upper(trim(p_item_column_name)),
                           item_format_mask = trim(p_item_format_mask), item_default = trim(p_item_default),
                           item_low_value = trim(p_item_low_value), item_high_value = trim(p_item_high_value),
                           item_mandatory = v_mandatory, item_display_only = v_display_only,
                           item_hidden = v_hidden
     WHERE screen_id = p_screen_id AND item_name = nm;
    COMMIT;
    owa_util.redirect_url('appdoc.screen?p_screen_id=' || p_screen_id);
  END;

  PROCEDURE item_delete(p_screen_id IN NUMBER, p_item_name IN VARCHAR2) IS
  BEGIN
    DELETE FROM screen_item WHERE screen_id = p_screen_id AND item_name = p_item_name;
    COMMIT;
    owa_util.redirect_url('appdoc.screen?p_screen_id=' || p_screen_id);
  END;

  -- TABLE ACCESS ---------------------------------------------------------------------------
  FUNCTION has(arr IN owa.vc_arr, v IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    FOR k IN 1 .. arr.COUNT LOOP
      IF arr(k) = v THEN RETURN 'Y'; END IF;
    END LOOP;
    RETURN 'N';
  END;

  PROCEDURE crud_save(p_screen_id IN NUMBER, p_tables IN owa.vc_arr DEFAULT appdoc.empty,
                      p_c IN owa.vc_arr DEFAULT appdoc.empty, p_r IN owa.vc_arr DEFAULT appdoc.empty,
                      p_u IN owa.vc_arr DEFAULT appdoc.empty, p_d IN owa.vc_arr DEFAULT appdoc.empty,
                      p_new_table IN VARCHAR2 DEFAULT NULL) IS
    t VARCHAR2(30);
    c VARCHAR2(1); r VARCHAR2(1); up VARCHAR2(1); d VARCHAR2(1);
  BEGIN
    FOR k IN 1 .. p_tables.COUNT LOOP
      t := p_tables(k);
      c := has(p_c, t); r := has(p_r, t); up := has(p_u, t); d := has(p_d, t);
      IF c = 'N' AND r = 'N' AND up = 'N' AND d = 'N' THEN
        DELETE FROM screen_crud WHERE screen_id = p_screen_id AND table_name = t;
      ELSE
        UPDATE screen_crud SET create_records = c, read_records = r, update_records = up, delete_records = d
         WHERE screen_id = p_screen_id AND table_name = t;
      END IF;
    END LOOP;
    t := upper(trim(p_new_table));
    IF t IS NOT NULL THEN
      INSERT INTO screen_crud (screen_id, table_name, create_records, read_records, update_records, delete_records)
      SELECT p_screen_id, t, 'N', 'Y', 'N', 'N' FROM dual
       WHERE NOT EXISTS (SELECT 1 FROM screen_crud WHERE screen_id = p_screen_id AND table_name = t);
    END IF;
    COMMIT;
    owa_util.redirect_url('appdoc.screen?p_screen_id=' || p_screen_id);
  END;

  -- TECHNICAL REFERENCE --------------------------------------------------------------------
  PROCEDURE reference(p_app_id IN VARCHAR2 DEFAULT NULL, p_screen_id IN NUMBER DEFAULT NULL) IS
    a       app_row%ROWTYPE;
    grp     VARCHAR2(200) := '#';
    open_l  BOOLEAN := FALSE;
    n       NUMBER;
    total   NUMBER;
  BEGIN
    SELECT * INTO a FROM app WHERE app_id = upper(p_app_id);
    SELECT count(*) INTO total FROM screen WHERE app_id = a.app_id AND screen_id = nvl(p_screen_id, screen_id);
    page_open(a.app_name || ' - Technical reference', esc(a.app_name) || ' &mdash; Technical reference', NULL,
              '<span>' || total || ' screen' || CASE WHEN total <> 1 THEN 's' END || ' &middot; ' || to_char(sysdate, 'Month DD, YYYY')
              || '</span><button type="button" onclick="window.print()">Print</button>', esc(a.app_description));
    htp.print('<script>
function docFilter(q) {
  q = q.toLowerCase();
  document.querySelectorAll("nav.toc li").forEach(function (li) { li.hidden = q && li.textContent.toLowerCase().indexOf(q) < 0; });
  document.querySelectorAll("nav.toc h4").forEach(function (h) { var ul = h.nextElementSibling; h.hidden = !!q && !ul.querySelector("li:not([hidden])"); });
  document.querySelectorAll("section.screen").forEach(function (s) { s.hidden = q && s.textContent.toLowerCase().indexOf(q) < 0; });
}
window.addEventListener("beforeprint", function () { document.querySelectorAll("details").forEach(function (d) { d.open = true; }); });
</script>');
    htp.print('<div class="layout"><nav class="toc" aria-label="Contents"><input type="search" placeholder="Filter screens and fields" oninput="docFilter(this.value)" aria-label="Filter">');
    FOR s IN (SELECT * FROM screen WHERE app_id = a.app_id AND screen_id = nvl(p_screen_id, screen_id)
               ORDER BY CASE WHEN display_order IS NULL THEN 1 ELSE 0 END, display_order, screen_title) LOOP
      IF group_label(s.screen_group, s.display_order) <> grp THEN
        IF open_l THEN htp.print('</ul>'); END IF;
        grp := group_label(s.screen_group, s.display_order);
        htp.print('<h4>' || esc(grp) || '</h4><ul>');
        open_l := TRUE;
      END IF;
      htp.print('<li><a href="#' || s.screen_code || '">' || esc(s.screen_title) || '<span>' || esc(s.screen_code) || '</span></a></li>');
    END LOOP;
    IF open_l THEN htp.print('</ul>'); END IF;
    htp.print('</nav><main>');
    FOR s IN (SELECT * FROM screen WHERE app_id = a.app_id AND screen_id = nvl(p_screen_id, screen_id)
               ORDER BY CASE WHEN display_order IS NULL THEN 1 ELSE 0 END, display_order, screen_title) LOOP
      htp.print('<section class="screen" id="' || s.screen_code || '"><header><h2>' || esc(s.screen_title) || '</h2>'
                || '<span class="code">' || esc(s.screen_code) || '</span><span class="grp">' || esc(group_label(s.screen_group, s.display_order)) || '</span></header>');
      IF a.image_file_prefix IS NOT NULL AND s.image_filename IS NOT NULL THEN
        htp.print('<img class="shot" alt="' || esc(s.screen_title) || '" src="' || a.image_file_prefix || s.image_filename || '">');
      END IF;
      IF s.screen_description IS NOT NULL THEN htp.print('<p class="desc">' || expand(s.screen_description, s.app_id) || '</p>'); END IF;
      n := 0;
      FOR c IN (SELECT * FROM screen_crud WHERE screen_id = s.screen_id ORDER BY table_name) LOOP
        n := n + 1;
        IF n = 1 THEN
          htp.print('<h3>Table access</h3><div class="scroll"><table class="crud"><thead><tr><th>Table</th><th class="c">Create</th>'
                    || '<th class="c">Read</th><th class="c">Update</th><th class="c">Delete</th></tr></thead><tbody>');
        END IF;
        htp.prn('<tr><td class="mono">' || brk(esc(c.table_name)) || '</td>');
        mark(c.create_records); mark(c.read_records); mark(c.update_records); mark(c.delete_records);
        htp.print('</tr>');
      END LOOP;
      IF n > 0 THEN htp.print('</tbody></table></div>'); END IF;
      n := 0;
      FOR i IN (SELECT * FROM screen_item WHERE screen_id = s.screen_id ORDER BY item_name) LOOP
        n := n + 1;
        IF n = 1 THEN
          htp.print('<h3>Screen fields</h3><div class="scroll"><table class="fields"><thead><tr><th>Prompt</th><th>Item</th><th>Type</th>'
                    || '<th>Rules</th><th>Description</th><th>Maps to</th></tr></thead><tbody>');
        END IF;
        htp.print('<tr><td>' || esc(i.item_prompt) || '</td><td class="mono">' || brk(esc(i.item_name)) || '</td><td class="mono type">'
                  || esc(i.item_data_type) || CASE WHEN i.item_max_size IS NOT NULL THEN '(' || i.item_max_size || ')' END || '</td><td>'
                  || CASE WHEN i.item_mandatory = 'Y' THEN chip('Required', 'req') END
                  || CASE WHEN i.item_display_only = 'Y' THEN chip('Display only', 'ro') END
                  || CASE WHEN i.item_hidden = 'Y' THEN chip('Hidden', 'hid') END
                  || CASE WHEN i.item_format_mask IS NOT NULL THEN chip('Format ' || esc(i.item_format_mask)) END
                  || CASE WHEN i.item_default IS NOT NULL THEN chip('Default ' || esc(i.item_default)) END
                  || CASE WHEN i.item_low_value IS NOT NULL THEN chip('&ge; ' || esc(i.item_low_value)) END
                  || CASE WHEN i.item_high_value IS NOT NULL THEN chip('&le; ' || esc(i.item_high_value)) END
                  || '</td><td>' || expand(i.item_description, s.app_id) || '</td><td class="mono">'
                  || brk(esc(i.item_table_name || CASE WHEN i.item_column_name IS NOT NULL THEN '.' || i.item_column_name END)) || '</td></tr>');
      END LOOP;
      IF n > 0 THEN htp.print('</tbody></table></div>'); END IF;
      IF s.screen_help IS NOT NULL THEN
        htp.print('<details><summary>Help text</summary><div class="help">' || expand(s.screen_help, s.app_id) || '</div></details>');
      END IF;
      htp.print('</section>');
    END LOOP;
    htp.print('<p class="foot">Generated by AppDoc from the application data dictionary.</p></main></div>');
    page_close;
  EXCEPTION WHEN no_data_found THEN
    owa_util.redirect_url('appdoc.home');
  END;

  -- HELP -----------------------------------------------------------------------------------
  PROCEDURE help(p_app_id IN VARCHAR2 DEFAULT NULL, p_screen_code IN VARCHAR2 DEFAULT NULL, p_ui IN VARCHAR2 DEFAULT 'forms') IS
    a     app_row%ROWTYPE;
    cnt   NUMBER;
    title VARCHAR2(200);
  BEGIN
    SELECT * INTO a FROM app WHERE app_id = upper(p_app_id);
    SELECT count(*) INTO cnt FROM screen WHERE app_id = a.app_id AND screen_code = nvl(upper(p_screen_code), screen_code);
    IF p_screen_code IS NOT NULL THEN
      FOR s IN (SELECT screen_title FROM screen WHERE app_id = a.app_id AND screen_code = upper(p_screen_code)) LOOP
        title := s.screen_title;
      END LOOP;
    END IF;
    page_open('Help' || CASE WHEN title IS NOT NULL THEN ' - ' || title END,
              'Help' || CASE WHEN title IS NOT NULL THEN ' &mdash; ' || esc(title) END, NULL,
              '<button type="button" onclick="window.close()">Close</button>', esc(a.app_name));
    htp.print('<div class="single" style="max-width:880px">');
    IF cnt = 0 THEN
      htp.print('<section class="screen"><p class="empty">There is no help for this screen yet.</p></section>');
    END IF;
    IF cnt > 1 THEN
      htp.print('<section class="card" style="columns:2 240px">');
      FOR s IN (SELECT screen_code, screen_title FROM screen WHERE app_id = a.app_id
                 ORDER BY CASE WHEN display_order IS NULL THEN 1 ELSE 0 END, display_order, screen_title) LOOP
        htp.print('<a style="display:block;padding:2px 0" href="#' || s.screen_code || '">' || esc(s.screen_title) || '</a>');
      END LOOP;
      htp.print('</section>');
    END IF;
    FOR s IN (SELECT * FROM screen WHERE app_id = a.app_id AND screen_code = nvl(upper(p_screen_code), screen_code)
               ORDER BY CASE WHEN display_order IS NULL THEN 1 ELSE 0 END, display_order, screen_title) LOOP
      htp.print('<section class="screen" id="' || s.screen_code || '">');
      IF cnt > 1 THEN
        htp.print('<header><h2>' || esc(s.screen_title) || '</h2><span class="code">' || esc(s.screen_code) || '</span></header>');
      END IF;
      htp.print('<div class="help">' || coalesce(expand(s.screen_help, a.app_id, p_ui), expand(s.screen_description, a.app_id, p_ui),
                '<p class="empty">There is no help for this screen yet.</p>') || '</div>');
      IF cnt = 1 THEN
        htp.print('<div class="actions"><button class="btn primary" type="button" onclick="window.close()">Close</button></div>');
      END IF;
      htp.print('</section>');
    END LOOP;
    htp.print('</div>');
    page_close;
  EXCEPTION WHEN no_data_found THEN
    owa_util.redirect_url('appdoc.home');
  END;

  -- EXPORT ---------------------------------------------------------------------------------
  FUNCTION q(v IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    IF v IS NULL THEN RETURN 'NULL'; END IF;
    RETURN '''' || replace(v, '''', '''''') || '''';
  END;

  FUNCTION qn(v IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN nvl(to_char(v), 'NULL');
  END;

  PROCEDURE export(p_app_id IN VARCHAR2) IS
    a app_row%ROWTYPE;
  BEGIN
    SELECT * INTO a FROM app WHERE app_id = upper(p_app_id);
    owa_util.mime_header('text/plain', FALSE);
    htp.p('Content-Disposition: attachment; filename="appdoc-' || lower(a.app_id) || '.sql"');
    owa_util.http_header_close;
    htp.p('-- AppDoc export: ' || a.app_name || ' (' || a.app_id || '), ' || to_char(sysdate, 'YYYY-MM-DD HH24:MI'));
    htp.p('-- Replaces the application''s rows. Run it where AppDoc''s tables are.');
    htp.p('SET DEFINE OFF');
    htp.p('DELETE FROM screen_item WHERE screen_id IN (SELECT screen_id FROM screen WHERE app_id = ' || q(a.app_id) || ');');
    htp.p('DELETE FROM screen_crud WHERE screen_id IN (SELECT screen_id FROM screen WHERE app_id = ' || q(a.app_id) || ');');
    htp.p('DELETE FROM screen WHERE app_id = ' || q(a.app_id) || ';');
    htp.p('DELETE FROM app WHERE app_id = ' || q(a.app_id) || ';');
    htp.p('INSERT INTO app (app_id, app_name, app_description, app_schema, image_file_prefix) VALUES ('
          || q(a.app_id) || ', ' || q(a.app_name) || ', ' || q(a.app_description) || ', ' || q(a.app_schema) || ', ' || q(a.image_file_prefix) || ');');
    -- Screen ids come from the database it is loaded into; fields and table access find their
    -- screen by application and code, so the script loads beside other applications.
    FOR s IN (SELECT * FROM screen WHERE app_id = a.app_id ORDER BY screen_id) LOOP
      htp.p('INSERT INTO screen (screen_id, screen_code, app_id, screen_title, screen_group, display_order, source_filename, '
            || 'master_table_name, detail_table_name, image_filename, screen_description, screen_help, screen_user_notes) VALUES ('
            || 'screen_seq.NEXTVAL, ' || q(s.screen_code) || ', ' || q(s.app_id) || ', ' || q(s.screen_title) || ', ' || q(s.screen_group)
            || ', ' || qn(s.display_order) || ', ' || q(s.source_filename) || ', ' || q(s.master_table_name) || ', ' || q(s.detail_table_name)
            || ', ' || q(s.image_filename) || ', ' || q(s.screen_description) || ', ' || q(s.screen_help) || ', ' || q(s.screen_user_notes) || ');');
      FOR i IN (SELECT * FROM screen_item WHERE screen_id = s.screen_id ORDER BY item_name) LOOP
        htp.p('INSERT INTO screen_item (screen_id, item_name, item_prompt, item_description, item_table_name, item_column_name, '
              || 'item_max_size, item_mandatory, item_data_type, item_format_mask, item_display_only, item_default, item_low_value, '
              || 'item_high_value, item_hidden) SELECT screen_id, ' || q(i.item_name) || ', ' || q(i.item_prompt) || ', '
              || q(i.item_description) || ', ' || q(i.item_table_name) || ', ' || q(i.item_column_name) || ', ' || qn(i.item_max_size) || ', '
              || q(i.item_mandatory) || ', ' || q(i.item_data_type) || ', ' || q(i.item_format_mask) || ', ' || q(i.item_display_only) || ', '
              || q(i.item_default) || ', ' || q(i.item_low_value) || ', ' || q(i.item_high_value) || ', ' || q(i.item_hidden)
              || ' FROM screen WHERE app_id = ' || q(a.app_id) || ' AND screen_code = ' || q(s.screen_code) || ';');
      END LOOP;
      FOR c IN (SELECT * FROM screen_crud WHERE screen_id = s.screen_id ORDER BY table_name) LOOP
        htp.p('INSERT INTO screen_crud (screen_id, table_name, create_records, read_records, update_records, delete_records) SELECT screen_id, '
              || q(c.table_name) || ', ' || q(c.create_records) || ', ' || q(c.read_records) || ', '
              || q(c.update_records) || ', ' || q(c.delete_records)
              || ' FROM screen WHERE app_id = ' || q(a.app_id) || ' AND screen_code = ' || q(s.screen_code) || ';');
      END LOOP;
    END LOOP;
    htp.p('COMMIT;');
  END;

END appdoc;
/
