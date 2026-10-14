-- A small PL/SQL Web Toolkit application: departments and their employees,
-- written the way mod_plsql applications were -- one package, HTP to write
-- the page, a form that posts back to a procedure, a redirect after a save;
-- file upload into the document table, download through the document path
-- (wpg_docload), and a CSV export.
--
--   bin/run --demo          then  http://127.0.0.1:8800/hr/
--
-- The demo's DAD: document table HR_DOCS, document path docs, document
-- procedure hr_web.download.

CREATE TABLE IF NOT EXISTS dept (
  deptno NUMBER(2) PRIMARY KEY,
  dname  VARCHAR2(14),
  loc    VARCHAR2(13)
);

CREATE TABLE IF NOT EXISTS emp (
  empno    NUMBER(4) PRIMARY KEY,
  ename    VARCHAR2(10),
  job      VARCHAR2(9),
  hiredate DATE,
  sal      NUMBER(7,2),
  deptno   NUMBER(2) REFERENCES dept (deptno)
);

CREATE SEQUENCE emp_seq START WITH 8000;

INSERT INTO dept VALUES (10, 'ACCOUNTING', 'NEW YORK');
INSERT INTO dept VALUES (20, 'RESEARCH', 'DALLAS');
INSERT INTO dept VALUES (30, 'SALES', 'CHICAGO');
INSERT INTO emp VALUES (7839, 'KING', 'PRESIDENT', DATE '1981-11-17', 5000, 10);
INSERT INTO emp VALUES (7782, 'CLARK', 'MANAGER', DATE '1981-06-09', 2450, 10);
INSERT INTO emp VALUES (7566, 'JONES', 'MANAGER', DATE '1981-04-02', 2975, 20);
INSERT INTO emp VALUES (7788, 'SCOTT', 'ANALYST', DATE '1987-04-19', 3000, 20);
INSERT INTO emp VALUES (7698, 'BLAKE', 'MANAGER', DATE '1981-05-01', 2850, 30);
INSERT INTO emp VALUES (7499, 'ALLEN', 'SALESMAN', DATE '1981-02-20', 1600, 30);
COMMIT;

CREATE OR REPLACE PACKAGE hr_web AS
  PROCEDURE home;
  PROCEDURE dept(deptno IN NUMBER);
  PROCEDURE emp_form(empno IN NUMBER DEFAULT NULL, deptno IN NUMBER DEFAULT NULL);
  PROCEDURE emp_save(empno    IN NUMBER DEFAULT NULL,
                     ename    IN VARCHAR2,
                     job      IN VARCHAR2 DEFAULT NULL,
                     hiredate IN VARCHAR2 DEFAULT NULL,
                     sal      IN NUMBER DEFAULT NULL,
                     deptno   IN NUMBER);
  PROCEDURE emp_delete(empno IN NUMBER);
  PROCEDURE documents;
  PROCEDURE upload(p_file IN VARCHAR2 DEFAULT NULL);
  PROCEDURE download;
  PROCEDURE export_csv;
END hr_web;
/

CREATE OR REPLACE PACKAGE BODY hr_web AS

  PROCEDURE page_open(title IN VARCHAR2) IS
  BEGIN
    htp.p('<!doctype html><html><head><meta charset="utf-8">');
    htp.title(title);
    htp.p('<style>body{font:14px/1.5 system-ui,sans-serif;margin:2rem;color:#1b1c1e}'
          || 'table{border-collapse:collapse}td,th{border:1px solid #d5d8dd;padding:.3rem .6rem}'
          || 'th{background:#f2f3f5;text-align:left}a{color:#1a5fb4}'
          || 'label{display:block;margin:.4rem 0}input{font:inherit}</style>');
    htp.p('</head><body>');
    htp.p('<p><a href="hr_web.home">Departments</a> &middot; '
          || '<a href="hr_web.documents">Documents</a> &middot; '
          || '<a href="hr_web.export_csv">Employees as CSV</a></p>');
    htp.header(1, title);
  END;

  PROCEDURE page_close IS
  BEGIN
    htp.p('</body></html>');
  END;

  PROCEDURE home IS
  BEGIN
    page_open('Departments');
    htp.p('<table><tr><th>No</th><th>Department</th><th>Location</th><th>Staff</th></tr>');
    FOR d IN (SELECT d.deptno, d.dname, d.loc,
                     (SELECT COUNT(*) FROM emp e WHERE e.deptno = d.deptno) staff
              FROM dept d ORDER BY d.deptno) LOOP
      htp.p('<tr><td>' || d.deptno || '</td><td>'
            || htf.anchor('hr_web.dept?deptno=' || d.deptno, d.dname)
            || '</td><td>' || d.loc || '</td><td>' || d.staff || '</td></tr>');
    END LOOP;
    htp.p('</table>');
    page_close;
  END;

  PROCEDURE dept(deptno IN NUMBER) IS
    title VARCHAR2(100);
  BEGIN
    SELECT dname INTO title FROM dept d WHERE d.deptno = dept.deptno;
    page_open(title);
    htp.p('<table><tr><th>No</th><th>Name</th><th>Job</th><th>Hired</th><th>Salary</th><th></th></tr>');
    FOR e IN (SELECT empno, ename, job, hiredate, sal FROM emp e
              WHERE e.deptno = dept.deptno ORDER BY ename) LOOP
      htp.p('<tr><td>' || e.empno || '</td><td>' || e.ename || '</td><td>' || e.job
            || '</td><td>' || TO_CHAR(e.hiredate, 'YYYY-MM-DD')
            || '</td><td>' || TO_CHAR(e.sal, '99990.00') || '</td><td>'
            || htf.anchor('hr_web.emp_form?empno=' || e.empno, 'Edit') || '</td></tr>');
    END LOOP;
    htp.p('</table>');
    htp.p('<p>' || htf.anchor('hr_web.emp_form?deptno=' || deptno, 'New employee') || '</p>');
    page_close;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      owa_util.status_line(404, 'No such department');
      htp.p('No department ' || deptno);
  END;

  PROCEDURE emp_form(empno IN NUMBER DEFAULT NULL, deptno IN NUMBER DEFAULT NULL) IS
    e emp%ROWTYPE;
  BEGIN
    IF empno IS NOT NULL THEN
      SELECT * INTO e FROM emp x WHERE x.empno = emp_form.empno;
    ELSE
      e.deptno := deptno;
    END IF;
    page_open(CASE WHEN empno IS NULL THEN 'New employee' ELSE 'Employee ' || e.ename END);
    htp.p('<form method="post" action="hr_web.emp_save">');
    IF empno IS NOT NULL THEN
      htp.p('<input type="hidden" name="empno" value="' || e.empno || '">');
    END IF;
    htp.p('<input type="hidden" name="deptno" value="' || e.deptno || '">');
    htp.p('<label>Name <input name="ename" value="' || e.ename || '" required></label>');
    htp.p('<label>Job <input name="job" value="' || e.job || '"></label>');
    htp.p('<label>Hired <input name="hiredate" type="date" value="'
          || TO_CHAR(e.hiredate, 'YYYY-MM-DD') || '"></label>');
    htp.p('<label>Salary <input name="sal" value="' || e.sal || '"></label>');
    htp.p('<p><button>Save</button></p></form>');
    IF empno IS NOT NULL THEN
      htp.p('<form method="post" action="hr_web.emp_delete">'
            || '<input type="hidden" name="empno" value="' || e.empno || '">'
            || '<button>Delete</button></form>');
    END IF;
    page_close;
  END;

  PROCEDURE emp_save(empno    IN NUMBER DEFAULT NULL,
                     ename    IN VARCHAR2,
                     job      IN VARCHAR2 DEFAULT NULL,
                     hiredate IN VARCHAR2 DEFAULT NULL,
                     sal      IN NUMBER DEFAULT NULL,
                     deptno   IN NUMBER) IS
    hired DATE := TO_DATE(NULLIF(hiredate, ''), 'YYYY-MM-DD');
  BEGIN
    IF empno IS NULL THEN
      INSERT INTO emp (empno, ename, job, hiredate, sal, deptno)
      VALUES (emp_seq.NEXTVAL, UPPER(ename), UPPER(job), hired, sal, deptno);
    ELSE
      UPDATE emp x SET ename = UPPER(emp_save.ename), job = UPPER(emp_save.job),
                       hiredate = hired, sal = emp_save.sal
       WHERE x.empno = emp_save.empno;
    END IF;
    owa_util.redirect_url('hr_web.dept?deptno=' || deptno);
  END;

  PROCEDURE documents IS
  BEGIN
    page_open('Documents');
    htp.p('<table><tr><th>Name</th><th>Type</th><th>Size</th><th>Uploaded</th></tr>');
    FOR d IN (SELECT name, mime_type, doc_size, last_updated FROM hr_docs ORDER BY last_updated DESC, name) LOOP
      htp.p('<tr><td>' || htf.anchor('docs/' || REPLACE(d.name, ' ', '%20'),
                                     SUBSTR(d.name, INSTR(d.name, '/') + 1))
            || '</td><td>' || d.mime_type || '</td><td>' || d.doc_size
            || '</td><td>' || TO_CHAR(d.last_updated, 'YYYY-MM-DD HH24:MI') || '</td></tr>');
    END LOOP;
    htp.p('</table>');
    htp.p('<form method="post" action="hr_web.upload" enctype="multipart/form-data">'
          || '<p><input type="file" name="p_file" required> <button>Upload</button></p></form>');
    page_close;
  END;

  -- The gateway has already stored the file; p_file is the name it is under.
  PROCEDURE upload(p_file IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    owa_util.redirect_url('hr_web.documents');
  END;

  -- The document procedure: /hr/docs/F12ab34cd/report.pdf
  PROCEDURE download IS
    name VARCHAR2(512) := SUBSTR(owa_util.get_cgi_env('PATH_INFO'), LENGTH('/docs/') + 1);
  BEGIN
    wpg_docload.download_file(name);
  END;

  PROCEDURE export_csv IS
  BEGIN
    owa_util.mime_header('text/csv', FALSE);
    htp.p('Content-Disposition: attachment; filename="employees.csv"');
    owa_util.http_header_close;
    htp.p('EMPNO,ENAME,JOB,HIREDATE,SAL,DEPTNO');
    FOR e IN (SELECT empno, ename, job, hiredate, sal, deptno FROM emp ORDER BY empno) LOOP
      htp.p(e.empno || ',' || e.ename || ',' || e.job || ',' || TO_CHAR(e.hiredate, 'YYYY-MM-DD')
            || ',' || e.sal || ',' || e.deptno);
    END LOOP;
  END;

  PROCEDURE emp_delete(empno IN NUMBER) IS
    d NUMBER;
  BEGIN
    SELECT deptno INTO d FROM emp x WHERE x.empno = emp_delete.empno;
    DELETE FROM emp x WHERE x.empno = emp_delete.empno;
    owa_util.redirect_url('hr_web.dept?deptno=' || d);
  END;

END hr_web;
/
