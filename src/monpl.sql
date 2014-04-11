CREATE OR REPLACE PACKAGE monpl AS
--------------------------------------------------------------------------------
-- Name:       monpl
--
-- Utility procedures to support logging and timing of PL/SQL
-- data load activities and errors.
--
--
-- REVISIONS:
-- Date         Author           Description
-- -----------  ---------------  ------------------------------------
-- 29-JUN-2010  Kevin Custer     Initial Revision
--------------------------------------------------------------------------------

  PROCEDURE startp
  (
    p_build_id   IN  NUMBER,
    p_build_date IN  DATE,
    p_program    IN  VARCHAR2,
    p_process    IN  VARCHAR2,
    p_log_level  IN  NUMBER,
    p_msg        IN  VARCHAR2,
    p_id         OUT NUMBER
  );

  PROCEDURE endp
  (
    p_id      IN  NUMBER
  );

  PROCEDURE raise_err
  (
    p_id      IN  NUMBER,
    p_errm    IN  VARCHAR2
  );

  PROCEDURE raise_err
  (
    p_build_id   IN  NUMBER,
    p_build_date IN  DATE,
    p_program    IN  VARCHAR2,
    p_process    IN  VARCHAR2,
    p_errm       IN  VARCHAR2
  );

  PROCEDURE get_bld_id
  (
    p_build_id   OUT NUMBER,
    p_build_date OUT DATE
  );

  PROCEDURE test_call;
  
END monpl;
/


CREATE OR REPLACE PACKAGE BODY monpl AS

  -- Exceptions
  e_invalid_log_level     EXCEPTION;
  e_dupe_log_level1       EXCEPTION;
  e_dupe_log_level2       EXCEPTION;

  -- Global Constants
  gv_start_status         CONSTANT MONPL_STATUS.STATUS%TYPE  :=  'RUNNING';
  gv_end_status           CONSTANT MONPL_STATUS.STATUS%TYPE  :=  'COMPLETED';
  gv_error_status         CONSTANT MONPL_STATUS.STATUS%TYPE  :=  'ERROR';

  gv_package_name         CONSTANT VARCHAR2(30)              :=  'MONPL';

  gv_invld_log_level_msg  CONSTANT MONPL_STATUS.MSG%TYPE     :=  gv_package_name || ': Invalid Log Level';
  gv_dupe_log_level1_msg  CONSTANT MONPL_STATUS.MSG%TYPE     :=  gv_package_name || ': Log Level 1 already exists for the build';
  gv_dupe_log_level2_msg  CONSTANT MONPL_STATUS.MSG%TYPE     :=  gv_package_name || ': Log Level 2 already exists for the procedure';

--------------------------------------------------------------------------------
-- Name:       startp
-- Purpose:    Insert new log record to log table.  This procedure overload
--               accepts a custom log message.
--------------------------------------------------------------------------------
PROCEDURE startp
(
  p_build_id   IN  NUMBER,
  p_build_date IN  DATE,
  p_program    IN  VARCHAR2,
  p_process    IN  VARCHAR2,
  p_log_level  IN  NUMBER,
  p_msg        IN  VARCHAR2,
  p_id         OUT NUMBER
)
IS

  lv_msg_prepend        VARCHAR2(30);

BEGIN

  SELECT monpl_status_seq.NEXTVAL
    INTO p_id
    FROM dual;

  IF p_log_level = 1 THEN

    -- Check for Existing Log Level 1 for Build
    DECLARE

      ln_id NUMBER;

    BEGIN

      SELECT log_id
        INTO ln_id
        FROM monpl_status
       WHERE build_id = p_build_id
         AND build_date = p_build_date
         AND log_level = 1;

      RAISE e_dupe_log_level1;

    EXCEPTION
      WHEN e_dupe_log_level1 THEN
        RAISE;
      WHEN NO_DATA_FOUND THEN
        NULL;

    END;

    lv_msg_prepend := '';

  ELSIF p_log_level = 2 THEN

    lv_msg_prepend := '    > ';

  ELSIF p_log_level = 3 THEN

    lv_msg_prepend := '        + ';

  ELSIF p_log_level = 4 THEN

    lv_msg_prepend := '            - ';

  ELSE

    RAISE e_invalid_log_level;

  END IF;

  INSERT INTO monpl_status
    (
      log_id,
      build_id,
      build_date,
      log_level,
      program,
      process,
      msg,
      status,
      start_time
    )
  VALUES
    (
      p_id,
      p_build_id,
      p_build_date,
      p_log_level,
      UPPER(p_program),
      UPPER(p_process),
      lv_msg_prepend || p_msg,
      gv_start_status,
      SYSDATE
    );

  COMMIT;

EXCEPTION
  WHEN e_invalid_log_level THEN
    raise_err(p_build_id, p_build_date, p_program, p_process, gv_invld_log_level_msg);
    RAISE;
  WHEN e_dupe_log_level1 THEN
    raise_err(p_build_id, p_build_date, p_program, p_process, gv_dupe_log_level1_msg);
    RAISE;
  WHEN e_dupe_log_level2 THEN
    raise_err(p_build_id, p_build_date, p_program, p_process, gv_dupe_log_level2_msg);
    RAISE;
  WHEN OTHERS THEN
    RAISE;
    --NULL;

END startp;


--------------------------------------------------------------------------------
-- Name:       endp
-- Purpose:    Ends a given step in the log table.  Calculates elapsed time for
--               the step.
--------------------------------------------------------------------------------
PROCEDURE endp
(
  p_id      IN  NUMBER
)
IS
BEGIN

  UPDATE monpl_status
     SET (end_time, min_elapsed, status) = (SELECT SYSDATE,
                                                   TO_CHAR(
                                                    (SYSDATE - start_time) * 24 * 60, -- calculate minutes elapsed
                                                     '99999D9'),
                                                   gv_end_status
                                              FROM monpl_status
                                             WHERE log_id = p_id)
   WHERE log_id = p_id;

  COMMIT;

END endp;


--------------------------------------------------------------------------------
-- Name:       raise_err
-- Purpose:    Flags a log record with error message.  This procedure overload
--               accepts a log ID and updates that log entry with the error.
--------------------------------------------------------------------------------
PROCEDURE raise_err
(
  p_id      IN  NUMBER,
  p_errm    IN  VARCHAR2
)
IS
BEGIN

  UPDATE monpl_status
     SET msg    = p_errm,
         status = gv_error_status
   WHERE log_id     = p_id;

  COMMIT;

END raise_err;


--------------------------------------------------------------------------------
-- Name:       raise_err
-- Purpose:    Flags a log record with error message.  This procedure overload
--               inserts a new log entry with the error.
--------------------------------------------------------------------------------
PROCEDURE raise_err
(
  p_build_id   IN  NUMBER,
  p_build_date IN  DATE,
  p_program    IN  VARCHAR2,
  p_process    IN  VARCHAR2,
  p_errm       IN  VARCHAR2
)
IS
BEGIN

  INSERT INTO monpl_status
    (
      log_id,
      build_id,
      build_date,
      log_level,
      program,
      process,
      msg,
      status,
      start_time
    )
  VALUES
    (
      monpl_status_seq.NEXTVAL,
      p_build_id,
      p_build_date,
      'E',
      p_program,
      p_process,
      p_errm,
      gv_error_status,
      SYSDATE
    );

  COMMIT;

END raise_err;


PROCEDURE get_bld_id
(
  p_build_id   OUT NUMBER,
  p_build_date OUT DATE
)
IS
BEGIN

  SELECT monpl_bld_seq.NEXTVAL,
         SYSDATE
    INTO p_build_id,
         p_build_date
    FROM dual;

EXCEPTION
  WHEN OTHERS THEN
    RAISE;

END get_bld_id;

PROCEDURE test_call
IS
BEGIN

  dbms_output.put_line(who_am_i);

END test_call;

END monpl;
/