[Setting category="Main" name="Enable plugin" description="If disabled, the plugin will not alter the ModWork folder."]
bool enablePlugin = true;

[Setting category="Main" name="Enable notifications" description="If enabled, you will be notified on startup when new textures/presets are released."]
bool enableNotifications = true;

[Setting category="Main" hidden]
string listSignature = "";

[Setting category="Main" hidden name="Toggle plugin"]
bool togglePlugin = true;

[Setting category="Main" hidden name="Default action when existing mod" description="What action to do by default when a map with a custom mod is loaded."]
string defaultActionWhenMod = "unset";

[Setting category="Main" hidden name="Action for each map" description="What the player decided for each custom modded map."]
string mapPreferences = "{}";

[Setting category="Main" hidden name="Selected ModWorks" description="What ModWork is selected for each surface"]
string selectedModWorks = "{}";

[Setting category="Main" hidden name="Selected quality" description="Selected quality for textures"]
string textureQuality = "2K";

[Setting category="Main" hidden name="Wood status" description="Current status of wood texture"]
string woodTexture = "unset";