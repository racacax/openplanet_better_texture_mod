namespace AdvancedSettings {
    [SettingsTab name="Advanced" icon="ListAlt"]
    void RenderSettings()
    {
        /* 
            Settings related to enabling/disabling textures are only available for ModWork
            Modless doesn't update textures on the go, so it's not relevant
        */
        if(modMethod == "ModWork") {
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
            UI::Separator(); 
            
            if(ConfirmationButton(Icons::Exchange + " Switch to Modless", vec2 ( ), "Switching to Modless requires to delete the ModWork folder, are you sure ?")) {
                modMethod = "Modless";
                IO::DeleteFolder(MODWORK_FOLDER, true);
                IO::DeleteFolder(MODWORK_DISABLED_FOLDER, true);
                UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - ModWork folder deleted", "ModWork folder has been deleted and plugin will be Modless after restart.", UI::HSV(0.51, 0.69, 0.9), 8000);       
            }
            UI::TextWrapped("Modless method allows you to have plugin textures alongside custom mods. However you will not be able to use new wood/old wood texures presets. Keep in mind any texture of a custom mod will override its corresponding texture in the plugin !\n"
            + Text::OpenplanetFormatCodes("$F93" + Icons::ExclamationTriangle + " A full game restart is required to enable Modless support.")); 
            UI::Separator(); 

            if(isActive) {
                UI::PushStyleColor(UI::Col::Button, vec4(1,0.8,0,1));
                if(UI::Button(Icons::PowerOff + " Disable plugin & ModWork")) {
                    ModWorkManager::DisableModWork();
                    enablePlugin = false;
                }
                UI::PopStyleColor(1);
                UI::TextWrapped("Disabling ModWork will move the ModWork folder to a new folder named ModWorkDisabled. Keep in mind it can also alter plugins such as Custom Skidmarks !"); 
                UI::Separator();
            } else {
                UI::PushStyleColor(UI::Col::Button, vec4(0, .8,0,1));
                if(UI::Button(Icons::PowerOff + " Enable plugin & ModWork")) {
                    ModWorkManager::EnableModwork();
                    enablePlugin = true;
                }
                UI::PopStyleColor(1);
                UI::TextWrapped("Enabling ModWork will move the ModWorkDisabled folder to the ModWork folder. Keep in mind it can also alter plugins such as Custom Skidmarks !"); 
                UI::Separator();
            }
        } else {
            
            if(ConfirmationButton(Icons::Exchange + " Switch to ModWork", vec2 ( ), "Are you sure you want to switch to ModWork ?")) {
                modMethod = "ModWork";
                TexturesLoading::updateAllSilent = true;
                TexturesLoading::updateAll = true;
                TexturesLoading::oldSettings = Json::Parse(selectedModWorks);
                UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Using ModWork", "Now using ModWork.", UI::HSV(0.51, 0.69, 0.9), 8000);       
            }
            UI::TextWrapped("ModWork allows you to apply textures on-the-go and have different textures for new and old wood. However, it cannot work alongside mods so both can't be activated at the same time. You can decide to disable plugin textures when there is a custom mod.");
            if(IO::FolderExists(MODWORK_FOLDER)) {
                UI::PushStyleColor(UI::Col::Text, vec4(1,0.8,0,1));
                UI::TextWrapped(Icons::ExclamationTriangle + " ModWork folder exists and is not related to Better Texture Mod. You need to delete it if you want mods to load.");
                UI::PopStyleColor(1);
            }
            UI::Separator();
        }

        if(IO::FolderExists(MODWORK_FOLDER)) {
            UI::PushStyleColor(UI::Col::Button, vec4(1,0,0,1));
            if(ConfirmationButton(Icons::TrashO + " Delete ModWork folder", vec2 ( ), "Are you sure you want to delete the ModWork folder ?")) {
                IO::DeleteFolder(MODWORK_FOLDER, true);
                IO::DeleteFolder(MODWORK_DISABLED_FOLDER, true);
                UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - ModWork folder deleted", "ModWork folder has been deleted.", UI::HSV(0.51, 0.69, 0.9), 8000);       
            }
            UI::PopStyleColor(1);
            UI::TextWrapped("Deleting ModWork folder will clear all custom textures (if using the ModWork method). Keep in mind it can also alter plugins such as Custom Skidmarks ! It might require game restart to reload textures."); 
            UI::Separator();
        }

        if(modMethod == "ModWork") {  
            UI::PushStyleColor(UI::Col::Button, vec4(1,0,0,1));
            if(ConfirmationButton(Icons::TrashO + " Delete extra \"Default\" textures", vec2 ( ), "Are you sure you want to delete duplicated default texture files ?")) {
                DeleteDefaultTextures();
                UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Textures deleted", "Default textures have been deleted.", UI::HSV(0.51, 0.69, 0.9), 8000);       
            }
            UI::PopStyleColor(1);
            UI::TextWrapped("If you switched one material from a custom setting back to \"Default\", default textures are most likely duplicated on your drive. Deleting them will save some space as they are not useful. However, you need to restart the game, otherwise those textures will appear black.");
            UI::Separator();
        }

        UI::PushStyleColor(UI::Col::Button, vec4(1,0,0,1));
        if(ConfirmationButton(Icons::TrashO + " Clear cache", vec2 ( ), "Are you sure you want to clear the cache ?")) {
            DeleteCachedTextures();
            UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Textures deleted", "Cache has been deleted.", UI::HSV(0.51, 0.69, 0.9), 8000);       
        }
        UI::PopStyleColor(1);
        UI::TextWrapped("Textures are stored in the plugin cache storage when you download them. Clearing cache will delete them but will NOT alter your current applied presets if you use the ModWork method. However custom textures will disapear on reboot if you use the Modless method (unless you reapply them).");
        
    }
}