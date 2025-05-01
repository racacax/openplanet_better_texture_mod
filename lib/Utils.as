/*
    List of all files of all presets of BetterTextureMod (applied or not)
*/
array<string> GetAllBTMFiles() {
    Json::Value data = TexturesLoading::GetList();
    array<string> files = {};
    if(data.Length > 0) {
        Json::Value selectedModWorksJ = Json::Parse(selectedModWorks);
        array<string>  materials = selectedModWorksJ.GetKeys();
        for(uint i = 0; i< materials.Length; i++) {
            auto presetFiles = data["materials"][materials[i]]["presets"][string(selectedModWorksJ[materials[i]])]["files"];
            for(uint j=0; j< presetFiles.Length; j++) {
                files.InsertLast(presetFiles[j]);
            }
        }
    }
    return files;
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

void CopyFile(const string &in from, const string &in to) {
    IO::File fromFile(from, IO::FileMode::Read);
    IO::File toFile(to, IO::FileMode::Write);
    while (!fromFile.EOF()) {
        toFile.Write(fromFile.Read(1 << 10));
    }
    toFile.Flush();
}


string GetMapUid() {
    auto app = cast<CTrackMania>(GetApp());
    if(app.RootMap !is null) {
        return app.RootMap.MapInfo.MapUid;
    }
    return "";
}


/*
    Get server join link if player on server
*/
string GetJoinLink() {
    auto app = cast<CTrackMania>(GetApp());
    return app.ManiaPlanetScriptAPI.CurrentServerJoinLink.Replace("#join", "#qjoin");
}

bool IsInAMap() {
    auto app = cast<CTrackMania>(GetApp());
    return app.RootMap !is null;
}

bool IsServer() {
    return GetJoinLink() != "";
}
/*
    Init plugin for first start or if new textures have been published. 
*/
void InitPlugin() {
    if(enablePlugin) {
        ModWorkManager::EnableModwork();
    }
     Json::Value data = TexturesLoading::GetList();
     if(modMethod == "Modless" && IO::FolderExists(MODWORK_FOLDER)) {
        if(ModWorkManager::IsModWorkBTMOnly() && hasTriggeredModWorkFolderCreation) { // Might happen if we apply textures and then not go into a map before closing the game
            hasTriggeredModWorkFolderCreation = false;
            IO::DeleteFolder(MODWORK_FOLDER, true);
        } else {
            UI::ShowNotification("Better Texture Mod - ModWork folder exists", 
                        "ModWork folder exists and it doesn't seem it has been created by plugin. "
                        "Plugin textures might not appear correctly. Please consider deleting/renaming it.", 8000);      
        }
     }
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
            auto presets = data["materials"][materials[i]]["presets-order"];
            if(!selectedModWorksJ.HasKey(materials[i])) {
                string preset = presets[0];
                selectedModWorksJ[materials[i]] = preset;
            }
        }
        selectedModWorks = Json::Write(selectedModWorksJ);
        TextureSettings::presets = Json::Array(); // if new materials are added, TextureSettings presets needs to be refreshed
        
        if(modMethod == "Modless" && enablePlugin) {
            if(IsInAMap()) { // Game restart required, we need to preload Fids to be able to edit them
                return;
            }
            /*
                if game did crash while applying textures on boot (most likely due to a breaking update),
                disablePluginNextBoot will be true and on next boot, plugin will be entirely disabled and 
                player will be informed about what happened. This will avoid any potential crash loop.
            */
            disablePluginNextBoot = true;
            Meta::SaveSettings();
            ModlessManager::PreloadFids(data["fids"]);
            ModlessManager::hasLoadedFids = true;
            TexturesLoading::oldSettings = Json::Parse(selectedModWorks);
            try {
                TexturesLoading::UpdateAll(true);
            } catch {
				string errorMessage = getExceptionInfo();
				error(errorMessage);
            }
            disablePluginNextBoot = false; 
            Meta::SaveSettings();
        }
     }
}

/* Delete all textures which have "Default" as a setting (need full game restart) */
void DeleteDefaultTextures() {
     Json::Value data = TexturesLoading::GetList();
     if(data.Length > 0) {
        array<string> materials = data["materials"].GetKeys();
        Json::Value selectedModWorksJ = Json::Parse(selectedModWorks);
        for(uint i = 0; i< materials.Length; i++) {
            string preset = selectedModWorksJ[materials[i]];
            if(preset == "Default") {
                Json::Value files = data["materials"][materials[i]]["presets"][preset]["files"];
                ModWorkManager::RemoveTexture(files, true);
            }
        }
        selectedModWorks = Json::Write(selectedModWorksJ);
     }
}

/* Delete all textures in the plugin Cache storage */
void DeleteCachedTextures() {
     IO::DeleteFolder(CACHE_FOLDER, true);
}

void setMinWidth(int width) {
	UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
	UI::Dummy(vec2(width, 0));
	UI::PopStyleVar();
}

/*
    Credits : XertroV for all the ExeBuild code
*/

uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}

bool PointerLooksOkay(uint64 ptr, bool aligned = true) {
    return ptr < 0x03ffddddeeee && ptr > 0x00ffddddeeee
    && (!aligned || (aligned && ptr & 0x7 == 0));
}

const uint16 O_MAP_TITLEID = GetOffset("CGameCtnChallenge", "TitleId");
const uint16 O_MAP_BUILDINFO_STR = O_MAP_TITLEID + 0x4;

// example: date=2024-01-10_12_53 git=126731-1573de4d161 GameVersion=3.3.0
// const uint32 ExpectedBuildVersionLength = 62;

string GetExeBuildDate() {
    try  {
        auto map = GetApp().RootMap;
        auto strPtr = Dev::GetOffsetUint64(map, O_MAP_BUILDINFO_STR);
        auto strLen = Dev::GetOffsetUint32(map, O_MAP_BUILDINFO_STR + 0xC);
        // Check the length is what we expect, with some tolerance, and that the pointer looks valid. String pointers aren't necessarily aligned.
        if (strLen < 50 || strLen > 75 || !PointerLooksOkay(strPtr, false)) return "2024-01-01";
        return Dev::GetOffsetString(map, O_MAP_BUILDINFO_STR).Split("_")[0].Split("=")[1];
    } catch {
        return "2024-01-01";
    }
}

bool IsOldWood() {
    const string exeBuild = GetExeBuildDate().Replace("-", "");
    const int var = Text::ParseInt(exeBuild);
    return (var < 20231115);
}

/*
    Some presets can only applied with ModWork because textures need to be loaded dynamically
*/
bool CanApplyPreset(Json::Value preset) {
    return modMethod == "ModWork" || !bool(preset["is-modwork-only"]);
}

void UpdateAllTextures() {
	TexturesLoading::UpdateAll();
}

bool IsSafeToApply() {
    return modMethod == "ModWork" || !IsInAMap();
}