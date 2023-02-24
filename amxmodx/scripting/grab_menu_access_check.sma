#include <amxmodx>
#include <grab_modular>

public stock const PluginName[] = "Grab Menu: Access Check"
public stock const PluginVersion[] = "1.0.0"
public stock const PluginAuthor[] = "twisterniq"

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
}

public grab_menu_item_access_check(id, iTarget, iItemId, szAccess[])
{
    return (get_user_flags(id) & read_flags(szAccess)) ? GRAB_ALLOWED : GRAB_BLOCKED
}
