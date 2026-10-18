set define off
------------------------------------------------------------------------------
-- web_wiki schema - FRESH INSTALL (Oracle 12.2 or later; written for 19c/23ai)
------------------------------------------------------------------------------

create sequence ddg_wiki_seq start with 1 nocache;
create sequence ddg_wiki_data_pk_seq nocache;
create sequence ddg_wiki_data_set_seq nocache;

-- One row per saved revision. The highest ID for a TOPIC is the current page.
create table ddg_wiki
(
    id            number default on null ddg_wiki_seq.nextval not null
   ,topic         varchar2(80 char) not null
   ,lasteditor    varchar2(10)
   ,owner         varchar2(10)
   ,lastupdate    date default sysdate not null
   ,creation      date default sysdate not null
   ,ownerlock     varchar2(1)
   ,pageclob      clob
   ,excludesearch varchar2(1)
   ,deleted       varchar2(1)
   ,constraint ddg_wiki_pk_idx  primary key (id)
   ,constraint ddg_wiki_lock_ck check (ownerlock in ('Y','N'))
   ,constraint ddg_wiki_excl_ck check (excludesearch in ('Y','N'))
   ,constraint ddg_wiki_del_ck  check (deleted in ('1'))
);

comment on table  ddg_wiki               is 'Wiki page revisions; the highest ID per TOPIC is the current page';
comment on column ddg_wiki.id            is 'PK';
comment on column ddg_wiki.lastupdate    is 'When this revision was saved (set on insert only)';
comment on column ddg_wiki.creation      is 'When the page was first created (carried forward to each revision)';
comment on column ddg_wiki.ownerlock     is 'Y = only the owner may edit';
comment on column ddg_wiki.excludesearch is 'Y = hidden from other users'' searches';
comment on column ddg_wiki.deleted       is '1 = soft deleted (removed for good by web_wiki.purge_wiki)';

create index ddg_wiki_topic_idx  on ddg_wiki (topic, deleted, id);
create index ddg_wiki_utopic_idx on ddg_wiki (upper(topic));

-- Every save is a new revision, so the timestamp is stamped on insert only.
-- Updates (rename, delete, link fix-ups) leave LASTUPDATE alone so history keeps real times.
create or replace trigger ddg_wiki_bi_trg
before insert on ddg_wiki
for each row
begin
  :new.lastupdate := sysdate;
  :new.creation   := nvl(:new.creation, sysdate);
end;
/

-- Form records. A dataset is one submitted form; each field value is split into
-- 1000-character chunks (SEQ) so multibyte text always fits in 4000 bytes.
-- VALNO numbers repeated fields with the same name (checkbox groups, multi-selects).
create table ddg_wiki_data
(
    pkid       number default on null ddg_wiki_data_pk_seq.nextval not null
   ,datasetid  number not null
   ,wikiid     number not null
   ,fieldname  varchar2(100 char) not null
   ,valno      number default 1 not null
   ,fieldvalue varchar2(4000)
   ,seq        number not null
   ,dtcreated  date default sysdate
   ,dtupdated  date default sysdate
   ,whocreated varchar2(10)
   ,whoupdated varchar2(10)
   ,constraint ddg_wiki_data_pk      primary key (pkid)
   ,constraint ddg_wiki_data_wiki_fk foreign key (wikiid) references ddg_wiki (id)
);

comment on table ddg_wiki_data is 'Records saved from forms on wiki pages';

create index ddg_wiki_data_set_idx  on ddg_wiki_data (datasetid, fieldname, valno, seq);
create index ddg_wiki_data_wiki_idx on ddg_wiki_data (wikiid);

create or replace trigger ddg_wiki_data_trg_bu_trg
before update on ddg_wiki_data
for each row
begin
  :new.dtupdated := sysdate;
end;
/

-- Tables that "database forms" (dbtable="..." on the page form) may write to.
-- Nothing is writable until an administrator adds a row here.
create table ddg_wiki_form_tables
(
    table_name   varchar2(128) not null
   ,pk_column    varchar2(128) not null
   ,min_seclevel number default 1 not null
   ,enabled      varchar2(1) default 'Y' not null
   ,constraint ddg_wiki_form_tables_pk primary key (table_name)
   ,constraint ddg_wiki_form_tables_ck check (enabled in ('Y','N'))
);

comment on table ddg_wiki_form_tables is 'Whitelist of tables wiki database forms may insert/update (same schema, upper-case names)';
-- example:  insert into ddg_wiki_form_tables (table_name, pk_column, min_seclevel) values ('MY_TABLE', 'MY_ID', 2);

-- Default WikiHelp page (only created if there isn't one already).
-- Brackets and braces are written as HTML entities so the examples display literally.
insert into ddg_wiki (topic, lasteditor, owner, pageclob)
select 'WikiHelp', null, null, q'~<h2>Wiki help</h2>
<p><b>Links.</b> Type &#91;&#91;Document Name&#93;&#93; to link to another document, or &#91;&#91;Document Name|text to show&#93;&#93; to show different text. Following a link to a document that doesn't exist yet lets you create it.</p>
<p><b>Editing.</b> Click [Modify]. The toolbar handles formatting, tables, images and links; the HTML button switches to the page source. Ctrl+S saves. Every save keeps the earlier version under History, where any revision can be viewed, restored or deleted. If someone else saves while you are editing, the wiki shows you both versions instead of overwriting.</p>
<p><b>Lock and No-Search.</b> The owner of a document can lock it so only they can edit it, and can hide it from other people's searches.</p>
<p><b>Forms.</b> From the Form... menu choose Insert form, then add fields inside it. When someone fills it in and clicks Save, the answers are kept as a record of this document; [Records] lists them and opens any record for changes. A database form writes straight to a table instead: name each field DB_COLUMN (DBDT_COLUMN for dates), and an administrator must allow the table in DDG_WIKI_FORM_TABLES.</p>
<p><b>Scripts and styles.</b> Write &#123;script&#125;...&#123;/script&#125; or &#123;style&#125;...&#123;/style&#125;; they become real script and style tags when the page is shown. A page script can define useronload() to run after the page loads, and can read p_arg (the p_arg URL parameter). &#91;USERID] is replaced with your user id.</p>~'
from dual
where not exists (select 1 from ddg_wiki where upper(topic) = 'WIKIHELP');
commit;
