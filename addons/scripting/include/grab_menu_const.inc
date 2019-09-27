#if defined _grab_menu_const_included
    #endinput
#endif
#define _grab_menu_const_included

#define MAX_MENUNAME_LENGTH 64
#define MAX_MENUKEY_LENGTH 32

enum GrabItemTeam (<<= 1)
{
    GRAB_TEAM_T = 1,
    GRAB_TEAM_CT,
    GRAB_TEAM_SPECTATOR
};

enum GrabItemProp
{
    GRAB_PROP_NAME = 1,
    GRAB_PROP_KEY,
    GRAB_PROP_TEAM,
    GRAB_PROP_TARGET_TEAM,
    GRAB_PROP_ACCESS
};
