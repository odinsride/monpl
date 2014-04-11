CREATE OR REPLACE PACKAGE test_monpl AS

PROCEDURE build_main;

PROCEDURE subroutine_1;

PROCEDURE subroutine_2;

END test_monpl;


CREATE OR REPLACE PACKAGE BODY test_monpl AS

  gv_program              monpl_status.program%TYPE     := 'TEST_MONPL';
  gn_build_id             monpl_status.build_id%TYPE;   
  gn_build_date           DATE;

PROCEDURE build_main IS

  lv_process              monpl_status.process%TYPE     := 'BUILD_MAIN';
  
  ln_process_id           monpl_status.log_id%TYPE;

BEGIN

  -- Create a build_id and build_date for this program
  monpl.get_bld_id(gn_build_id, gn_build_date);
  
  monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 1, 'Executing TEST_MONPL Program', ln_process_id);
  
    subroutine_1;
    subroutine_2;

  monpl.endp(ln_process_id);
  
END build_main;


PROCEDURE subroutine_1 IS

  lv_process              monpl_status.process%TYPE     := 'SUBROUTINE_1';
  
  ln_process_id           monpl_status.log_id%TYPE;
  ln_ctl_id               monpl_status.log_id%TYPE;

BEGIN

  monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 2, 'Executing ' || lv_process || ' process', ln_process_id);
  
    -- Perform Substeps
    monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 3, 'Performing ' || lv_process || ' substep 1', ln_ctl_id);
      -- Do some things
    monpl.endp(ln_ctl_id);
    
    monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 3, 'Performing ' || lv_process || ' substep 2', ln_ctl_id);
      -- Do some things
    monpl.endp(ln_ctl_id);

  monpl.endp(ln_process_id);
  
END subroutine_1;


PROCEDURE subroutine_2 IS

  lv_process              monpl_status.process%TYPE     := 'SUBROUTINE_2';
  
  ln_process_id           monpl_status.log_id%TYPE;
  ln_ctl_id               monpl_status.log_id%TYPE;
  ln_sub_id               monpl_status.log_id%TYPE;

BEGIN

  monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 2, 'Executing ' || lv_process || ' process', ln_process_id);
  
    -- Perform Substeps
    monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 3, 'Performing ' || lv_process || ' substep 1', ln_ctl_id);
      -- Do some things
    monpl.endp(ln_ctl_id);
    
    monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 3, 'Performing ' || lv_process || ' substep 2', ln_ctl_id);
      -- Do some things
      
      -- Track finer-grain things, like insert progress
      FOR i IN 1 .. 20 LOOP
        monpl.startp(gn_build_id, gn_build_date, gv_program, lv_process, 4, 'Inserting Record Set #' || i, ln_sub_id);
        monpl.endp(ln_sub_id);
      END LOOP;
      
    monpl.endp(ln_ctl_id);

  monpl.endp(ln_process_id);
  
END subroutine_2;

END test_monpl;