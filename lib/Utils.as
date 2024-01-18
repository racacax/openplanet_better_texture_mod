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
            bool isOldWood = IsOldWood();
            if(woodTexture == "unset" || (isOldWood && woodTexture == "new") || (!isOldWood && woodTexture == "old")) {
                ManageWoodTextures(isOldWood);
                woodTexture = (isOldWood ? "old" : "new");
            }
        }
    } else {
        currentMap = "";
    }
}

/*
    Switch old wood / new wood textures depending on the map played
*/
void ManageWoodTextures(bool isOldWood) {
     Json::Value data = ModWorkLoading::list;
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
                    ModWorkLoading::ExchangeFiles(baseFile, oldFile);
                    ModWorkLoading::ExchangeFiles(fileName, baseFile);
                }
            }
        }
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
     if(data.Length > 0) {
        const string signature = data["signature"];
        if(signature != listSignature) {
            listSignature = signature;
            if(enableNotifications) {
                UI::ShowNotification(Icons::Kenney::InfoCircle + " Better Texture Mod - " + string(data["title"]), string(data["message"])+ "\n\nYou can disable these notifications in OpenPlanet => Settings => BetterTextureMod => Main.", UI::HSV(0.75, 0.95, 0.87), 16000);
            }
        }
        array<string> materials = data["materials"].GetKeys();
        Json::Value selectedModWorksJ = Json::Parse(selectedModWorks);
        for(uint i = 0; i< materials.Length; i++) {
            if(!selectedModWorksJ.HasKey(materials[i])) {
                auto presets = data["materials"][materials[i]]["presets-order"];
                string preset = presets[0];
                selectedModWorksJ[materials[i]] = preset;
            }
        }
        selectedModWorks = Json::Write(selectedModWorksJ);
        TextureSettings::presets = Json::Array(); // if new materials are added, TextureSettings presets needs to be refreshed
     }
}
/*
    Method to automatically disable a button when ModWork is loading
*/
bool DynamicButton(const string&in label, const vec2&in size = vec2 ( )) {
    UI::BeginDisabled(ModWorkLoading::displayModWorkLoading);
    auto button = UI::Button(label, size);
    UI::EndDisabled();
    return button;
}

/* Delete all textures which have "Default" as a setting (need full game restart) */
void DeleteDefaultTextures() {
     Json::Value data = ModWorkLoading::GetList();
     if(data.Length > 0) {
        array<string> materials = data["materials"].GetKeys();
        Json::Value selectedModWorksJ = Json::Parse(selectedModWorks);
        for(uint i = 0; i< materials.Length; i++) {
            string preset = selectedModWorksJ[materials[i]];
            if(preset == "Default") {
                Json::Value files = data["materials"][materials[i]]["presets"][preset]["files"];
                ModWorkLoading::RemoveTexture(files, true);
            }
        }
        selectedModWorks = Json::Write(selectedModWorksJ);
     }
}

void setMinWidth(int width) {
	UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
	UI::Dummy(vec2(width, 0));
	UI::PopStyleVar();
}


string GetExeBuildDate() {
    try  {
        return Dev::GetOffsetString(GetApp().RootMap, 0x78).Split("_")[0].Split("=")[1];
    } catch {
        return "2024-01-01";
    }
}

bool IsOldWood() {
    const string exeBuild = GetExeBuildDate().Replace("-", "");
    const int var = Text::ParseInt(exeBuild);
    return (var < 20231115);
}