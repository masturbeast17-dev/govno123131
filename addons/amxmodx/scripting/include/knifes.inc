#if defined _knifes_included
    #endinput
#endif

#define _knifes_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib knifes
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib knifes
    #endif
#else
    #pragma library knifes
#endif

native zp_knife_add(const szName[], const iCost)

forward knife_item_selected(iPlayer, iItemIndex)

native show_knife_menu(id)