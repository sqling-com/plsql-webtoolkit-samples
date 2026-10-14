# PL/SQL Web Toolkit samples

Two applications written the way mod_plsql applications are: PL/SQL packages that write
their pages with `HTP`, forms that post back to a procedure, and a redirect after a save.
Both run on Oracle's PL/SQL gateway (mod_plsql, or ORDS in PL/SQL gateway mode) and,
unchanged, on [sqling](https://sqling.com)'s gateway, where they are live demos.

| Sample | What it is | Live demo |
|---|---|---|
| [`hr/`](hr/install.sql) | Departments and employees: list, edit, save, delete; file upload and download through the document table; a CSV export. | [sqling.com/pro/owart/hr/](https://sqling.com/pro/owart/hr/) |
| [`appdoc/`](appdoc/install.sql) | **AppDoc**: technical documentation and user help kept by application. | [sqling.com/pro/owart/appdoc/](https://sqling.com/pro/owart/appdoc/) |

The demos are part of sqling Pro (sign-in required).

## HR

Load `hr/install.sql` into a schema and give its DAD `hr_web.home` as the default page.
Uploads and downloads go through a mod_plsql document table, `HR_DOCS` (document path
`docs`, document procedure `hr_web.download`), which the DAD's administrator creates:

```sql
CREATE TABLE hr_docs (
  name          VARCHAR2(256) UNIQUE NOT NULL,
  mime_type     VARCHAR2(128),
  doc_size      NUMBER,
  dad_charset   VARCHAR2(128),
  last_updated  DATE,
  content_type  VARCHAR2(128),
  blob_content  BLOB
);
```

## AppDoc

AppDoc keeps an application's documentation in four tables:

- `APP`: one row per application;
- `SCREEN`: its screens, each with a description, user help, team notes and a section to be listed under;
- `SCREEN_ITEM`: each screen's fields, with prompt, type, size, rules, and the table and column behind them;
- `SCREEN_CRUD`: which tables each screen creates, reads, updates and deletes.

From those rows it publishes two pages: a **technical reference**, with a filterable contents
panel, table access, fields and a print layout, and the **user help**. Its own screens
maintain every row, and **Export** writes an application's rows out as a script that loads
into any AppDoc beside the applications already there.

Data Design Group, Inc. designed the data dictionary in 2003 to document its PL/SQL web
applications. AppDoc is that design brought forward as an application of its own.

The rows can be typed in, but they usually start from a harvest of the application's source:
its pages, their parameters and the tables their SQL names, or, for Oracle Forms, its
modules, items and blocks. People then write the descriptions and help. The sample
application is **Northwind Traders**, seven Oracle Forms modules:

| File | |
|---|---|
| `appdoc/install.sql` | AppDoc's tables and its PL/SQL package `APPDOC` |
| `appdoc/northwind-harvest.sql` | the Northwind forms as harvested: 7 screens, 151 fields, their table access |
| `appdoc/northwind-docs.sql` | the written half: descriptions and help for every form and field |

### Running it

Load the three scripts in that order into a schema, then point a PL/SQL gateway DAD at it
with `appdoc.home` as the default page:

```sql
@appdoc/install.sql
@appdoc/northwind-harvest.sql
@appdoc/northwind-docs.sql
```

Both samples compile on Oracle Database 23ai, and AppDoc's pages run there under its PL/SQL
Web Toolkit. On an earlier release, drop the `IF NOT EXISTS` from the `CREATE TABLE` statements.

## License

MIT; see [LICENSE](LICENSE).
