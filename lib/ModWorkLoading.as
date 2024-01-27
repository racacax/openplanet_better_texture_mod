namespace ModWorkLoading {
    const string BASE_URL = "https://bettertexturemod.racacax.fr/";
    bool displayModWorkLoading = false;
    string currentMaterial = "";
    string currentFile = "";
    int progress = 0;
    int total = 0;
    Json::Value list = Json::Array();

    Json::Value oldSettings = Json::Value();
    bool updateAll = false;
    array<string> hasPreviousTextures = {};

    string updateOne = "";
    bool reloadModWorkPictures = false;

    /*
        Update all textures
    */
    void UpdateAll() {
        hasPreviousTextures = {};
        EnableModwork();
        updateAll = false;
        auto oldKeys = oldSettings.GetKeys();
        for(uint i = 0; i<oldKeys.Length; i++) {
            string oldMaterial = oldKeys[i];
            string oldPreset = oldSettings[oldKeys[i]];
            auto files = list["materials"][oldMaterial]["presets"][oldPreset]["files"];
            if(RemoveTexture(files)) {
                hasPreviousTextures.InsertLast(oldMaterial);
            }
        }
        auto currentSettings = Json::Parse(selectedModWorks);
        auto keys = currentSettings.GetKeys();
        for(uint i = 0; i<keys.Length; i++) {
            string material = keys[i];
            string preset = currentSettings[keys[i]];
            auto files = list["materials"][material]["presets"][preset]["files"];
            ApplyTexture(textureQuality, material, preset, files);
        }
    }

    /*
        Update one specific material related textures
    */
    void UpdateOne() {
        EnableModwork();
        hasPreviousTextures = {};
        string materialToUpdate = updateOne;
        updateOne = "";
        string oldPreset = oldSettings[materialToUpdate];
        auto files = list["materials"][materialToUpdate]["presets"][oldPreset]["files"];
        if(RemoveTexture(files)) {
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
            auto listTmp = API::GetAsyncJson(BASE_URL + "json/1.0.1.json");
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
    void DownloadTexture(const string &in quality, const string &in material, const string &in preset, const string &in file) {
        API::GetAsync(BASE_URL + "ModWork/" + quality + "/" + material + "/" + preset + "/" + file).SaveToFile(GetCurrentFolder() + "/" + file);
    }

    /*
        Download all files related to material and apply them by putting them in the ModWork folder
    */
    void ApplyTexture(const string &in quality, const string &in material, const string &in preset, Json::Value files) {
        displayModWorkLoading = true;
        total = files.Length;
        currentMaterial = material; 
        for(uint i = 0; i < files.Length; i++) {
            progress = i +1;
            currentFile = string(files[i]);
            const string path = GetCurrentFolder() + "/" + currentFile;
            // If preset is Default, we don't download any texture, unless custom textures were applied before
            if(preset != "Default" || hasPreviousTextures.Find(material) > -1) {
                IO::Delete(path);
                DownloadTexture(quality, material, preset, currentFile);
            }   
        }
        if(bool(GetList()["materials"][currentMaterial]["is-wood"])) {
            for(uint i = 0; i < files.Length; i++) {
                progress = i +1;
                currentFile = string(files[i]);
                if(currentFile.Contains('_OldWood') && woodTexture == "old") {
                    const string baseFile = currentFile.Replace('_OldWood', "");
                    ModWorkLoading::ExchangeFiles(baseFile, currentFile);
                } else if(currentFile.Contains('_NewWood') && woodTexture == "new") {
                    const string baseFile = currentFile.Replace('_NewWood', "");
                    ModWorkLoading::ExchangeFiles(baseFile, currentFile);
                } 
            }
        }
        displayModWorkLoading = false;
        
        auto app = cast<CTrackMania>(GetApp());
        if(app.RootMap !is null) {
            RestartPrompt::displayRestartPrompt = true;
        }
    }

    /*
        Delete texture files
    */
    bool RemoveTexture(Json::Value files, bool withAlerts = false) {
        bool hasDeletedTextures = false;
        for(uint i = 0; i < files.Length; i++) {
            const string fileName = string(files[i]);
            const string path = GetCurrentFolder() + "/" + fileName;
            if(IO::FileExists(path)) {
                if(withAlerts) {
                  UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Texture deleted", fileName + " has been deleted.", UI::HSV(0.51, 0.26, 0.9), 8000);  
                }
                IO::Delete(path);
                hasDeletedTextures = true; // Notify there were indeed previous textures
            }
        }
        return hasDeletedTextures;
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
        const string fullFile1 = GetCurrentFolder() + "/" + file1;
        const string fullFile2 = GetCurrentFolder() + "/" + file2;
        IO::Move(fullFile1, fullFile2 + "_tmp");
        IO::Move(fullFile2, fullFile1);
        IO::Move(fullFile2 + "_tmp", fullFile2);
    }
}