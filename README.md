# PL/SQL Web Toolkit samples

Two applications written the way mod_plsql applications are: PL/SQL packages that write
their pages with `HTP`, forms that post back to a procedure, and a redirect after a save.
They run on your own computer with no Oracle Database. [sqling](https://sqling.com)'s
PL/SQL gateway runs the PL/SQL, and the data lives in SQLite.

| Sample | What it is |
|---|---|
| [`hr/`](hr/install.sql) | Departments and employees: list, edit, save, delete; file upload and download; a CSV export. |
| [`appdoc/`](appdoc/install.sql) | **AppDoc**: technical documentation and user help kept by application, with the Northwind Traders forms documented as its example. |

Both are also live demos on sqling Pro (sign-in required):
[HR](https://sqling.com/pro/owart/hr/) · [AppDoc](https://sqling.com/pro/owart/appdoc/).

## Run them on your computer

You need:

- **Python 3.9 or later** (macOS, Linux or Windows). Check with `python3 --version`.
- **sqling's PL/SQL gateway**: two Python packages, `sqlingpl-<version>.whl` (the sqling Engine)
  and `owart-<version>.whl` (the gateway). They come with sqling Pro; ask for them through
  [sqling.com/contact](https://sqling.com/contact/).

Then, in a terminal:

```sh
git clone https://github.com/sqling-com/plsql-webtoolkit-samples.git
cd plsql-webtoolkit-samples
python3 -m venv .venv
.venv/bin/pip install /path/to/sqlingpl-*.whl /path/to/owart-*.whl
.venv/bin/owart --config owart.json
```

On Windows, use `py -3 -m venv .venv`, `.venv\Scripts\pip install ...` and `.venv\Scripts\owart --config owart.json`.

Open <http://127.0.0.1:8800/>. It lists both samples:

- <http://127.0.0.1:8800/hr/>: the departments; click one to see and edit its employees.
- <http://127.0.0.1:8800/appdoc/>: the applications documented; open **Northwind Traders**.

Press Ctrl-C in the terminal to stop.

### Keeping your changes

[`owart.json`](owart.json) builds each sample in memory from its scripts every time the
gateway starts, so you always begin with the original data. To keep what you change, build
a database file once:

```sh
.venv/bin/sqling -d hr.sqlite hr/install.sql
.venv/bin/sqling -d appdoc.sqlite appdoc/install.sql
.venv/bin/sqling -d appdoc.sqlite appdoc/northwind-harvest.sql
.venv/bin/sqling -d appdoc.sqlite appdoc/northwind-docs.sql
```

Then, in `owart.json`, change each DAD's `"db": ":memory:"` to `"db": "hr.sqlite"` or
`"db": "appdoc.sqlite"`, and remove its `"install"` list. Each database is two files, for
example `hr.sqlite` and `hr_system.db`, which holds the PL/SQL. Keep them together.

### The settings

Each sample is a **DAD** in `owart.json`, as in mod_plsql:

| Setting | Meaning |
|---|---|
| `name` | pages are served at `/<name>/<procedure>`, e.g. `/hr/hr_web.home` |
| `db` | `:memory:` (a fresh database at every start), a `.sqlite` file, or a database bundle (`.zip`) |
| `install` | scripts run in order when the DAD starts (paths relative to `owart.json`) |
| `default_page` | the procedure `/<name>/` opens |
| `document_table`, `document_path`, `document_procedure` | mod_plsql's document settings: where uploads go and how `/<name>/docs/...` downloads are served |
| `max_upload` | the largest upload, in bytes |

At the top level, `port` (8800) and `host` (127.0.0.1) say where the gateway listens.

## HR

One package, `hr_web`, in the classic style:
- **Lists and forms:** a department list, each department's employees, and an employee form that posts back to `hr_web.emp_save`, which redirects after the save.
- **Files:** uploads go into the document table `HR_DOCS`, and downloads come out through `wpg_docload`.
- **Export:** the employees as a CSV file.

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

The rows can be typed in, but they usually start from a **harvest** of the application's
source. `owart-harvest`, installed with the gateway, reads it:
- **PL/SQL applications:** the pages, their parameters and the tables their SQL uses;
- **Oracle Forms:** the modules, their items and their blocks.

People then write the descriptions and help. The example application is **Northwind
Traders**, seven Oracle Forms modules:

| File | |
|---|---|
| `appdoc/install.sql` | AppDoc's tables and its PL/SQL package `APPDOC` |
| `appdoc/northwind-harvest.sql` | the Northwind forms as harvested: 7 screens, 151 fields, their table access |
| `appdoc/northwind-docs.sql` | the written half: descriptions and help for every form and field |

To document an application of your own, harvest its database and add the script to AppDoc's
`install` list, after `appdoc/install.sql`:

```sh
.venv/bin/owart-harvest myapp.sqlite --app MYAPP --name "My application" -o myapp-docs.sql
```

## On Oracle too

These are standard PL/SQL Web Toolkit applications, so they also run on Oracle's own
gateway, mod_plsql or ORDS. Both compile and run on Oracle Database 23ai. To use them there:
- **Loading:** load the scripts into a schema with SQL*Plus or SQLcl.
- **DADs:** point a DAD at the schema with the same default pages.
- **HR's document table:** create `HR_DOCS` with mod_plsql's standard columns (`NAME`, `MIME_TYPE`, `DOC_SIZE`, `DAD_CHARSET`, `LAST_UPDATED`, `CONTENT_TYPE`, `BLOB_CONTENT`).
- **Releases before 23ai:** drop the `IF NOT EXISTS` from the `CREATE TABLE` statements.

## License

MIT; see [LICENSE](LICENSE).
