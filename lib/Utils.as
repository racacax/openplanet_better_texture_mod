/*
    Disable ModWork by simply moving the ModWork folder. Content is not altered.
*/
void DisableModWork() {
    if (IO::FolderExists(MODWORK_FOLDER)) {
        trace("Disabling ModWork");
        MoveFolder(MODWORK_FOLDER, MODWORK_DISABLED_FOLDER);
    }
    isActive = false;
}
/*
    Enable ModWork by simply moving the ModWorkDisabled folder. If folder doesn't exist, it is created. Content is not altered.
*/
void EnableModwork() {
    trace("Enabling ModWork");
    isActive = true;
    if (IO::FolderExists(MODWORK_DISABLED_FOLDER)) {
        MoveFolder(MODWORK_DISABLED_FOLDER, MODWORK_FOLDER);
    } else {
        IO::CreateFolder(MODWORK_FOLDER);
    }
    if(!IO::FolderExists(MODWORK_FOLDER + "/Image")) {
        IO::CreateFolder(MODWORK_FOLDER + "/Image");
    }
}

/*
    Move recursively folder and files.
*/
void MoveFolder(const string &in from, const string &in to) {
	array<string> files = IO::IndexFolder(from, false);
    if(!IO::FolderExists(to)) {
        IO::CreateFolder(to);
    }
	for (uint i = 0; i < files.Length; i++) {
    	if(!IO::FileExists(files[i])) {
            MoveFolder(files[i], to + files[i].Split(from)[1]);
        } else {
            IO::Move(files[i], to + files[i].Split(from)[1]);
        }
	}
   IO::DeleteFolder(from);
}

/*
    Either get the ModWork or ModWorkDisabled folder depending of plugin status
*/
string GetCurrentFolder() {
    return ((isActive) ? MODWORK_FOLDER : MODWORK_DISABLED_FOLDER) + "/Image";
}

/*
    Check if player is on a map and if it has a mod already or not. ModWork will be enabled/disabled depending of preferences.
*/
void CheckCurrentMap() {
    auto app = cast<CTrackMania>(GetApp());
    if(app.RootMap !is null) {
        if(currentMap != app.RootMap.MapInfo.MapUid) {
            currentMap = app.RootMap.MapInfo.MapUid;
            string preference = MapPreferences::GetMapPreference(currentMap);
            if(app.RootMap.ModPackDesc !is null) {
                if(preference == "unset") {
                    PlayerPrompt::displayPlayerPrompt = true;
                }
                if(preference == "apply_modwork" && !isActive) {
                    EnableModwork();
                }
                if(preference == "disable_modwork" && isActive) {
                    DisableModWork();
                }
            } else {
                if(!isActive) {
                    EnableModwork();
                }
            }
        }
    } else {
        currentMap = "";
    }
}

/*
    Get server join link if player on server
*/
string GetJoinLink() {
    auto app = cast<CTrackMania>(GetApp());
    return app.ManiaPlanetScriptAPI.CurrentServerJoinLink.Replace("#join", "#qjoin");
}

bool IsServer() {
    return GetJoinLink() != "";
}
/*
    Init plugin for first start or if new textures have been published. Textures for each material will be downloaded automatically 
    if there is no preference for this material (typical of a first start)
*/
void InitPlugin() {
     Json::Value data = ModWorkLoading::GetList();
     array<string> materials = data["materials"].GetKeys();
     Json::Value selectedModWorksJ = Json::Parse(selectedModWorks);
     for(uint i = 0; i< materials.Length; i++) {
        if(!selectedModWorksJ.HasKey(materials[i])) {
            auto presets = data["materials"][materials[i]]["presets"].GetKeys();
            presets.SortAsc();
            selectedModWorksJ[materials[i]] = presets[0];
            ModWorkLoading::ApplyTexture(textureQuality, materials[i], presets[0], data["materials"][materials[i]]["presets"][presets[0]]["files"]);
        }
     }
     selectedModWorks = Json::Write(selectedModWorksJ);
}