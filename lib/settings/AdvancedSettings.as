namespace AdvancedSettings {
    [SettingsTab name="Advanced" icon="ListAlt"]
    void RenderSettings()
    {
        UI::Text("Do you want to disable plugin when a map has a custom mod ?");
        auto selectedStr = CHOICES[defaultActionWhenMod];
        if (UI::BeginCombo("##disablePluginWhenMod", selectedStr)) {
            for (uint i = 0; i < CHOICES_KEYS.Length; i++) {
                string action = CHOICES_KEYS[i];
                if(UI::Selectable(CHOICES[action], defaultActionWhenMod == action)) {
                    defaultActionWhenMod = action;
                }
            }
            UI::EndCombo();
        }
        auto app = cast<CTrackMania>(GetApp());
        if(app.RootMap !is null) {
            string preference = MapPreferences::GetMapPreference(app.RootMap.MapInfo.MapUid);
            if(app.RootMap.ModPackDesc !is null) {
                UI::Text("Disable plugin for this map");
                string selectedStr2 = CHOICES_FOR_MAP[preference];
                if (UI::BeginCombo("##disablePluginWhenModForMap", selectedStr2)) {
                for (uint i = 0; i < CHOICES_FOR_MAP_KEYS.Length; i++) {
                    string action2 = CHOICES_FOR_MAP_KEYS[i];
                    if(UI::Selectable(CHOICES_FOR_MAP[action2], selectedStr2 == action2)) {
                        MapPreferences::SetMapPreference(app.RootMap.MapInfo.MapUid, action2);
                        RestartPrompt::displayRestartPrompt = true;
                    }
                }
                UI::EndCombo();
                }   
            }
        UI::Text("You might need to reload the map for changes to take effect");
        }
        if(isActive) {
            UI::PushStyleColor(UI::Col::Button, vec4(1,0.8,0,1));
            if(UI::Button(Icons::PowerOff + " Disable plugin & ModWork")) {
                DisableModWork();
                enablePlugin = false;
            }
            UI::PopStyleColor(1);
            UI::TextWrapped("Disabling ModWork will move the ModWork folder to a new folder named ModWorkDisabled. Keep in mind it can also alter plugins such as Custom Skidmarks !"); 
        } else {
            UI::PushStyleColor(UI::Col::Button, vec4(0, .8,0,1));
            if(UI::Button(Icons::PowerOff + " Enable plugin & ModWork")) {
                EnableModwork();
                enablePlugin = true;
            }
            UI::PopStyleColor(1);
            UI::TextWrapped("Enabling ModWork will move the ModWorkDisabled folder to the ModWork folder. Keep in mind it can also alter plugins such as Custom Skidmarks !"); 
        }
        UI::PushStyleColor(UI::Col::Button, vec4(1,0,0,1));
        if(ConfirmationButton(Icons::TrashO + " Delete ModWork folder", vec2 ( ), "Are you sure you want to delete the ModWork folder ?")) {
            IO::DeleteFolder(MODWORK_FOLDER, true);
            IO::DeleteFolder(MODWORK_DISABLED_FOLDER, true);
            UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - ModWork folder deleted", "ModWork folder has been deleted.", UI::HSV(0.51, 0.69, 0.9), 8000);       
        }
        UI::PopStyleColor(1);
        UI::TextWrapped("Deleting ModWork folder will clear all custom textures. Keep in mind it can also alter plugins such as Custom Skidmarks !");
        
        UI::PushStyleColor(UI::Col::Button, vec4(1,0,0,1));
        if(ConfirmationButton(Icons::TrashO + " Delete extra \"Default\" textures", vec2 ( ), "Are you sure you want to delete duplicated default texture files ?")) {
            DeleteDefaultTextures();
            UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Textures deleted", "Default textures have been deleted.", UI::HSV(0.51, 0.69, 0.9), 8000);       
        }
        UI::PopStyleColor(1);
        UI::TextWrapped("If you switched one material from a custom setting back to \"Default\", default textures are most likely duplicated on your drive. Deleting them will save some space as they are not useful. However, you need to restart the game, otherwise those textures will appear black.");
        UI::PushStyleColor(UI::Col::Button, vec4(1,0,0,1));
        if(ConfirmationButton(Icons::TrashO + " Clear cache", vec2 ( ), "Are you sure you want to clear the cache ?")) {
            DeleteCachedTextures();
            UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Textures deleted", "Cache has been deleted.", UI::HSV(0.51, 0.69, 0.9), 8000);       
        }
        UI::PopStyleColor(1);
        UI::TextWrapped("Textures are stored in the plugin cache storage when you download them. Clearing cache will delete them but will NOT alter your current applied presets.");
    
    }
}