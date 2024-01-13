namespace ModWorkLoading {
    const string BASE_URL = "https://bettertexturemod.racacax.fr/ModWork";
    bool displayModWorkLoading = false;
    string currentMaterial = "";
    string currentFile = "";
    int progress = 0;
    int total = 0;
    Json::Value list = Json::Array();

    Json::Value oldSettings = Json::Value();
    bool updateAll = false;

    string updateOne = "";
    bool reloadModWorkPictures = false;

    /*
        Update all textures
    */
    void UpdateAll() {
        EnableModwork();
        updateAll = false;
        auto oldKeys = oldSettings.GetKeys();
        for(uint i = 0; i<oldKeys.Length; i++) {
            string oldMaterial = oldKeys[i];
            string oldPreset = oldSettings[oldKeys[i]];
            auto files = list["materials"][oldMaterial]["presets"][oldPreset]["files"];
            RemoveTexture(files);
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
        string materialToUpdate = updateOne;
        updateOne = "";
        string oldPreset = oldSettings[materialToUpdate];
        auto files = list["materials"][materialToUpdate]["presets"][oldPreset]["files"];
        RemoveTexture(files);
        auto currentSettings = Json::Parse(selectedModWorks);
        ApplyTexture(textureQuality, materialToUpdate, currentSettings[materialToUpdate], files);
    }

    /*
        Get current list of textures
    */
    Json::Value GetList() {
        if(list.Length == 0) {
            list = API::GetAsyncJson(BASE_URL + "/list.php");
        }
        return list;
    }

    /*
        Download texture file and putting it in the ModWork folder
    */
    void DownloadTexture(const string &in quality, const string &in material, const string &in preset, const string &in file) {
        API::GetAsync(BASE_URL + "/" + quality + "/" + material + "/" + preset + "/" + file).SaveToFile(GetCurrentFolder() + "/" + file);
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
            IO::Delete(path);
            DownloadTexture(quality, material, preset, currentFile);
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
    void RemoveTexture(Json::Value files) {
            for(uint i = 0; i < files.Length; i++) {
                const string path = GetCurrentFolder() + "/" + string(files[i]);
                IO::Delete(path);
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
            string selectedFile = files["files"][0];
            selectedFile = selectedFile.Replace(".dds", ".jpg");
            auto image = Images::CachedFromURL(BASE_URL + "/Thumbs/" + keys[i] + "/" + string(currentModWorks[keys[i]]) + "/" + selectedFile);
            TextureSettings::thumbs.Set(keys[i] , image);
        }
    }
}