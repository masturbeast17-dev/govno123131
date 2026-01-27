#if defined _presents_guns_included
    #endinput
#endif

#define _presents_guns_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib presents_guns
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib presents_guns
    #endif
#else
    #pragma library presents_guns
#endif

native give_fglauncher(id)