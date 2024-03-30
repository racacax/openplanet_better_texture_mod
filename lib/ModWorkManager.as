namespace ModWorkManager {
    bool isWaitingForReload = false;
    /*
    Disable ModWork by simply moving the ModWork folder. Content is not altered.
    */
    void DisableModWork() {
        if(modMethod == "ModWork") {
            if (IO::FolderExists(MODWORK_FOLDER)) {
                trace("Disabling ModWork");
                MoveFolder(MODWORK_FOLDER, MODWORK_DISABLED_FOLDER);
            }
            isActive = false;
        }
    }

    
    /*
        Either get the ModWork or ModWorkDisabled folder depending of plugin status
    */
    string GetCurrentFolder() {
        return ((isActive) ? MODWORK_FOLDER : MODWORK_DISABLED_FOLDER) + "/Image";
    }

    /*
        if player decides to reload the same map, we disable the ModWork.
    */
    void DisableIfReloadingSameMap() {
        if(isWaitingForReload) { // avoid to run multiple threads
            return ;
        }
        string currentMapUid = GetMapUid();
        while(IsInAMap()) { 
            if(currentMapUid != GetMapUid()) {
                break;
            }
            yield();
        }
        while(!IsInAMap()) { yield(); }
        if(currentMapUid == GetMapUid() && !isWaitingForReload) {
            isWaitingForReload = true;
            DisableModWork();
            MapLoading::ReloadMap();
            isWaitingForReload = false;
        }

    }

    /*
    Check if player is on a map and if it has a mod already or not. ModWork will be enabled/disabled depending of preferences.
    */
    void CheckCurrentMap() {
        auto app = cast<CTrackMania>(GetApp());
        if(app.RootMap !is null) {
            if(currentMap != app.RootMap.MapInfo.MapUid && modMethod == "ModWork") { // We only enable/disable if we use the ModWork method as it is useless with Modless
                currentMap = app.RootMap.MapInfo.MapUid;
                string preference = MapPreferences::GetMapPreference(currentMap);
                if(app.RootMap.ModPackDesc !is null) {
                    if(preference == "unset") {
                        PlayerPrompt::displayPlayerPrompt = true;
                    }
                    if(preference == "apply_modwork" && !isActive) {
                        EnableModwork();
                        if(enableDoubleLoading) {    
                            MapLoading::ReloadMap();
                        } else {
                            if(showReloadWarning) {
                                UI::ShowNotification("Better Texture Mod - Reload required", 
                                "Custom plugin textures are currently disabled. Reload map to enable them. "
                                "You can enable this automatically by enabling double loading in the settings.");
                            }
                        }
                    }
                    if(preference == "disable_modwork" && isActive) {
                        if(enableDoubleLoading) {
                            MapLoading::ReloadMap();
                            DisableModWork();
                        } else {
                            startnew(DisableIfReloadingSameMap);
                            if(showReloadWarning) {
                                UI::ShowNotification("Better Texture Mod - Reload required", 
                                "Custom map mod is currently not showing. Reload map to enable it. "
                                "You can enable this automatically by enabling double loading in the settings.");
                            }
                        }
                    }
                } else {
                    PlayerPrompt::displayPlayerPrompt = false;
                    if(!isActive) {
                        EnableModwork();
                        if(enableDoubleLoading) {
                            MapLoading::ReloadMap();
                        } else {
                            if(showReloadWarning) {
                                UI::ShowNotification("Better Texture Mod - Reload required", 
                                "Custom plugin textures are currently disabled. Reload map to enable them. "
                                "You can enable this automatically by enabling double loading in the settings.");
                            }
                        }
                    }
                }
                bool isOldWood = IsOldWood();
                if(woodTexture == "unset" || (isOldWood && woodTexture == "new") || (!isOldWood && woodTexture == "old")) {
                    ManageWoodTextures(isOldWood);
                    woodTexture = (isOldWood ? "old" : "new");
                }
            }
        } else {
            currentMap = "";
            PlayerPrompt::displayPlayerPrompt = false;
        }
    }

    
    /*
        Switch old wood / new wood textures depending on the map played
    */
    void ManageWoodTextures(bool isOldWood) {
        if(modMethod == "ModWork") {
            Json::Value data = TexturesLoading::list;
            if(data.Length > 0) {
                const string suffixStr = (isOldWood) ? "_OldWood" : "_NewWood";
                const string replacingSuffixStr = (woodTexture == "unset") ? "" : ((woodTexture == "new") ? "_NewWood" : "_OldWood");
                array<string> materials = data["materials"].GetKeys();
                Json::Value selectedModWorksJ = Json::Parse(selectedModWorks);
                for(uint i = 0; i< materials.Length; i++) {
                    string preset = selectedModWorksJ[materials[i]];
                    auto files = data["materials"][materials[i]]["presets"][preset]["files"];
                    for(uint j = 0; j < files.Length; j++) {
                        const string fileName = files[j];
                        const string oldFile = fileName.Replace(suffixStr, replacingSuffixStr);
                        const string baseFile = fileName.Replace(suffixStr, "");
                        if(fileName.Contains(suffixStr)) {
                            TexturesLoading::ExchangeFiles(baseFile, oldFile);
                            TexturesLoading::ExchangeFiles(fileName, baseFile);
                        }
                    }
                }
            }
        }
        
    }

    
    /*
        Check if there is any file related to the plugin in the ModWork folder
    */
    bool HasAnyBTMFile() {
        auto btmFiles = GetAllBTMFiles();
        auto modWorkFiles = IO::IndexFolder(GetCurrentFolder(), false);
        for(uint i=0; i < modWorkFiles.Length; i++) {
            array<string> split = modWorkFiles[i].Replace("\\", "/").Split("/");
            if(btmFiles.Find(split[split.Length - 1]) >= 0) {
                return true;
            }
        }
        return false;
    }

    /*
        Check if the ModWork folder contains only files related to the plugin (will return true if empty)
    */
    bool IsModWorkBTMOnly() {
        auto btmFiles = GetAllBTMFiles();
        auto modWorkFiles = IO::IndexFolder(MODWORK_FOLDER, true);
        for(uint i=0; i < modWorkFiles.Length; i++) {
            array<string> split = modWorkFiles[i].Replace("\\", "/").Split("/");
            if(split[split.Length - 2].ToLower() != "image" || btmFiles.Find(split[split.Length - 1]) == -1) {
                return false;
            }
        }
        return true;
    }

    /*
    Enable ModWork by simply moving the ModWorkDisabled folder. If folder doesn't exist, it is created. Content is not altered.
    */
    void EnableModwork() {
        isActive = true;
        if(modMethod == "ModWork") {
            trace("Enabling ModWork");
            if (IO::FolderExists(MODWORK_DISABLED_FOLDER)) {
                MoveFolder(MODWORK_DISABLED_FOLDER, MODWORK_FOLDER);
            } else {
                IO::CreateFolder(MODWORK_FOLDER);
            }
            if(!IO::FolderExists(MODWORK_FOLDER + "/Image")) {
                IO::CreateFolder(MODWORK_FOLDER + "/Image");
            }
        }
    }

    

    /*
        Delete texture files
    */
    bool RemoveTexture(Json::Value files, bool withAlerts = false) {
        bool hasDeletedTextures = false;
        if(modMethod == "ModWork") {
            for(uint i = 0; i < files.Length; i++) {
                const string fileName = string(files[i]);
                const string path = GetCurrentFolder() + "/" + fileName;
                if(IO::FileExists(path)) {
                    if(withAlerts) {
                    UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Texture deleted", fileName + " has been deleted.", UI::HSV(0.51, 0.69, 0.9), 8000);  
                    }
                    IO::Delete(path);
                    hasDeletedTextures = true; // Notify there were indeed previous textures
                }
            }
        }
        return hasDeletedTextures;
    }

}