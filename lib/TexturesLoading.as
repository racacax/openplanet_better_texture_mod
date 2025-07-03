namespace TexturesLoading {
    bool displayTexturesLoading = false;
    string currentMaterial = "";
    string currentFile = "";
    int progress = 0;
    int total = 0;
    Json::Value list = Json::Array();

    Json::Value oldSettings = Json::Value();
    bool updateAll = false;
    bool updateAllSilent = false;
    array<string> hasPreviousTextures = {};

    string updateOne = "";
    bool reloadModWorkPictures = false;

    string NormalizePath(const string &in path) {
        return path.Replace("\\", "/");
    }

    /*
        Update all textures
    */
    void UpdateAll(bool isSilent = false) {
        updateAll = false;
        hasPreviousTextures = {};
        ModWorkManager::EnableModwork();
        if(updateAllSilent) {
            isSilent = true;
            updateAllSilent = false;
        }
        auto oldKeys = oldSettings.GetKeys();
        for(uint i = 0; i<oldKeys.Length; i++) {
            string oldMaterial = oldKeys[i];
            string oldPreset = oldSettings[oldKeys[i]];
            auto files = list["materials"][oldMaterial]["presets"][oldPreset]["files"];
            if(ModWorkManager::RemoveTexture(files)) {
                hasPreviousTextures.InsertLast(oldMaterial);
            }
        }
        auto currentSettings = Json::Parse(selectedModWorks);
        auto keys = currentSettings.GetKeys();
        auto length = keys.Length;
        for(uint i = 0; i<length; i++) {
            string material = keys[i];
            string preset = currentSettings[keys[i]];
            auto files = list["materials"][material]["presets"][preset]["files"];
            ApplyTexture(textureQuality, material, preset, files, i == length - 1, isSilent);
        }
    }

    /*
        Update one specific material related textures
    */
    void UpdateOne() {
        hasPreviousTextures = {};
        string materialToUpdate = updateOne;
        updateOne = "";
        ModWorkManager::EnableModwork();
        string oldPreset = oldSettings[materialToUpdate];
        auto files = list["materials"][materialToUpdate]["presets"][oldPreset]["files"];
        if(ModWorkManager::RemoveTexture(files)) {
            hasPreviousTextures.InsertLast(materialToUpdate);
        }
        auto currentSettings = Json::Parse(selectedModWorks);
        string newPreset = currentSettings[materialToUpdate];
        auto newFiles = list["materials"][materialToUpdate]["presets"][newPreset]["files"];
        ApplyTexture(textureQuality, materialToUpdate, currentSettings[materialToUpdate], newFiles);
    }

    /*
        Get current list of textures
    */
    Json::Value GetList() {
        if(list.Length == 0) {
            auto listTmp = API::GetAsyncJson(BASE_URL + "json/2.0.0.json");
            if(listTmp.GetType() != Json::Type::Object) {
                error("Error while connecting to the API");
                UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Error", "An unexpected error occured while fetching the API. Try reloading the plugin. If the error persists, open an issue or DM racacax on Discord", UI::HSV(1.0, 1.0, 1.0), 16000);
            } else {
                list = listTmp;
            }
        }
        return list;
    }

    /*
        Download texture file and putting it in the ModWork folder
    */
    void DownloadTexture(const string &in quality, const string &in material, const string &in preset, const string &in file, const bool &in useCacheOnly = false) {
        string cachedFile = API::GetCachedAsync(
            BASE_URL + "ModWork/" + quality + "/" + material + "/" + preset + "/" + file, useCacheOnly);
        if(cachedFile == "") {
            warn("No cache for file " + file +", skipping...");
            return;
        }

        if(modMethod == "Modless") {
            ModlessManager::SetTexture(cachedFile, file);
        } else if(modMethod == "ModWork") {
            CopyFile(cachedFile, ModWorkManager::GetCurrentFolder() + "/" + file);
        }
    }

    /*
        Download all files related to material and apply them by putting them in the ModWork folder
    */
    void ApplyTexture(const string &in quality, const string &in material, const string &in preset, Json::Value files, bool changeRestartPromptStatus = true, bool isSilent = false) {
        displayTexturesLoading = true && !isSilent;
        RestartPrompt::displayRestartPrompt = false;
        total = files.Length;
        currentMaterial = material;
        for(uint i = 0; i < files.Length; i++) {
            progress = i +1;
            currentFile = string(files[i]);
            const string path = NormalizePath(ModWorkManager::GetCurrentFolder() + "/" + currentFile);
            // If preset is Default, we don't download any texture, unless custom textures were applied before
            if((preset != "Default" || (modMethod == "Modless" && !isSilent)) || hasPreviousTextures.Find(material) > -1) {
                if(modMethod == "ModWork") {
                    trace("Full file path: " + path);
                    if (IO::FileExists(path)) {
                        IO::Delete(path);
                        trace("[Delete] Removed: " + path);
                    } else {
                        warn("[Delete] File not found, skipping: " + path);
                    }
                }
                DownloadTexture(quality, material, preset, currentFile, isSilent);
            }
        }

        /* Managing old/new wood textures is only available with the ModWork method */
        if(modMethod == "ModWork") {
            if(bool(GetList()["materials"][currentMaterial]["is-wood"])) {
                for(uint i = 0; i < files.Length; i++) {
                    progress = i +1;
                    currentFile = string(files[i]);
                    if(currentFile.Contains('_OldWood') && woodTexture == "old") {
                        const string baseFile = currentFile.Replace('_OldWood', "");
                        TexturesLoading::ExchangeFiles(baseFile, currentFile);
                    } else if(currentFile.Contains('_NewWood') && woodTexture == "new") {
                        const string baseFile = currentFile.Replace('_NewWood', "");
                        TexturesLoading::ExchangeFiles(baseFile, currentFile);
                    }
                }
            }
        }

        displayTexturesLoading = false;

        auto app = cast<CTrackMania>(GetApp());
        if(app.RootMap !is null && changeRestartPromptStatus) {
            RestartPrompt::displayRestartPrompt = true && !isSilent;
        } else if(!isSilent && modMethod == "Modless") {
            startnew(ModlessManager::ReloadMap);
        }

    }

    /*
        Render view to let the user know about texture download status
    */
    void Render() {
        UI::TextWrapped("Textures are loading...");
        UI::Text("Current : " + currentMaterial + "("+ progress+ "/" + total + ")");
        UI::Text("File : " + currentFile);
    }

    /*
        Method to load Texture object for previews
    */
    void ReloadModWorkPictures() {
        reloadModWorkPictures = false;
        TextureSettings::thumbs = {};
        auto currentModWorks = TextureSettings::presets;
        auto keys = currentModWorks.GetKeys();
        for(uint i=0; i<keys.Length; i++) {
            auto files = GetList()["materials"][keys[i]]["presets"][string(currentModWorks[keys[i]])];
            string selectedFile = files["thumbnail"];
            auto image = Images::CachedFromURL(BASE_URL + "ModWork/Thumbs/" + keys[i] + "/" + string(currentModWorks[keys[i]]) + "/" + selectedFile);
            TextureSettings::thumbs.Set(keys[i] , image);
        }
    }

    /*
        Exchange two files respective path (for OldWood/NewWood)
    */
    void ExchangeFiles(const string file1, const string file2) {
        trace('Exchanging '+ file1 + " and " + file2);
        const string fullFile1 = ModWorkManager::GetCurrentFolder() + "/" + file1;
        const string fullFile2 = ModWorkManager::GetCurrentFolder() + "/" + file2;
        IO::Move(fullFile1, fullFile2 + "_tmp");
        IO::Move(fullFile2, fullFile1);
        IO::Move(fullFile2 + "_tmp", fullFile2);
    }
}
