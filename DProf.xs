#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static void
init_debugger()
{
    curstash = debstash;
    dbargs = GvAV(gv_AVadd((gv_fetchpv("args", GV_ADDMULTI, SVt_PVAV))));
    AvREAL_off(dbargs);
    DBgv = gv_fetchpv("DB", GV_ADDMULTI, SVt_PVGV);
    DBline = gv_fetchpv("dbline", GV_ADDMULTI, SVt_PVAV);
    DBsub = gv_HVadd(gv_fetchpv("sub", GV_ADDMULTI, SVt_PVHV));
    DBsingle = GvSV((gv_fetchpv("single", GV_ADDMULTI, SVt_PV)));
    sv_setiv(DBsingle, 0); 
    DBtrace = GvSV((gv_fetchpv("trace", GV_ADDMULTI, SVt_PV)));
    sv_setiv(DBtrace, 0); 
    DBsignal = GvSV((gv_fetchpv("signal", GV_ADDMULTI, SVt_PV)));
    sv_setiv(DBsignal, 0); 
    curstash = defstash;
}

MODULE = Apache::DProf		PACKAGE = Apache::DProf		

PROTOTYPES: DISABLE

int
init_debugger()

    CODE:
    if (!perldb) {
	perldb = PERLDB_ALL;
	init_debugger();
	RETVAL = TRUE;
    }
    else 
	RETVAL = FALSE;

    OUTPUT:
    RETVAL

int
init_DBsub()

    CODE:
    if(DBsub) {
        if((GvCV(DBsub) = perl_get_cv("DB::sub", FALSE)))
	   RETVAL = TRUE;
        else
	   RETVAL = FALSE;
    }
    else
	RETVAL = FALSE;


    OUTPUT:
    RETVAL
