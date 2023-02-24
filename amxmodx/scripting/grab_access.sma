#include <amxmodx>
#include <grab_modular>

public stock const PluginName[] = "Grab: Access"
public stock const PluginVersion[] = "1.0.0"
public stock const PluginAuthor[] = "twisterniq"

// Level of the grab access.
// If you don't know what it's for, don't change it.
const ACCESS_LEVEL = 1

new g_iAccess

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_access.txt")

    func_CreateCVars()
}

func_CreateCVars()
{
    new pCVar = create_cvar(
        .name = "grab_access",
        .string = "o",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_ACCESS_CVAR"))
    set_pcvar_string(pCVar, "")
    hook_cvar_change(pCVar, "onAccessChange")

    AutoExecConfig(true, "grab_access", "grab_modular")

    new szPath[PLATFORM_MAX_PATH]
    get_localinfo("amxx_configsdir", szPath, charsmax(szPath))

    if (file_exists(szPath))
    {
        // Execute configuration file to get access value immediately
        // because its value it's used in client_putinserver
        server_cmd("exec %s/plugins/grab_modular/grab_access.cfg", szPath)
    }
}

public client_putinserver(id)
{
    if (g_iAccess && get_user_flags(id) & g_iAccess)
    {
        grab_set_user_access(id, ACCESS_LEVEL)
    }
}

public onAccessChange(const pCVar, const szOldValue[], const szNewValue[])
{
    g_iAccess = read_flags(szNewValue)
}
