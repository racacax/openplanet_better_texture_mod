namespace TextureSettings {
    string selectedQuality = "";
    string selectedGroup = "";
    Json::Value presets = Json::Array();
    dictionary thumbs = {};
    [SettingsTab name="Textures" icon="PaintBrush"]
    void RenderSettings()
    {
      if(selectedQuality == "")
      {
        selectedQuality = textureQuality;
      }
      if(presets.Length == 0) {
        presets = Json::Parse(selectedModWorks);
      }
      if(TexturesLoading::list.Length > 0) {
        if(selectedGroup == "")
        {
            selectedGroup = TexturesLoading::list["groups"][0];
        }
        TexturesLoading::reloadModWorkPictures = true;
        if(!IsSafeToApply()) {
            UI::TextWrapped(Text::OpenplanetFormatCodes("$F93" + Icons::ExclamationTriangle + 
            " As a safety measure, you cannot apply textures while in a map if you use the Modless method. "
            "Leave the map to change textures."));
        }
        if(DynamicButton("Apply all##textures")) {
            enablePlugin = true;
            textureQuality = selectedQuality;
            TexturesLoading::oldSettings = Json::Parse(selectedModWorks);
            selectedModWorks = Json::Write(presets);
            TexturesLoading::updateAll = true;
        }

        UI::BeginTable("textureQuality", 3, UI::TableFlags::SizingFixedSame);
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("Texture Quality");
        UI::TableNextColumn();
        const auto qualities = TexturesLoading::list["qualities"];
        if (UI::BeginCombo("##textureQuality", selectedQuality)) {
                for (uint i = 0; i < qualities.Length; i++) {
                    string quality = qualities[i];
                    if(UI::Selectable(quality, quality == selectedQuality)) {
                        selectedQuality = quality;
                    }
                }
                UI::EndCombo();
        }
        UI::TableNextColumn();
        if(DynamicButton("Apply##textureQuality")) {
            enablePlugin = true;
            textureQuality = selectedQuality;
            TexturesLoading::oldSettings = Json::Parse(selectedModWorks);
            TexturesLoading::updateAll = true;
        }
        UI::EndTable();

        UI::BeginTable("group##textureGroups", 2, UI::TableFlags::SizingFixedFit);
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("Group");
        UI::TableNextColumn();
        const auto groups = TexturesLoading::list["groups"];
        setMinWidth(150);
        if (UI::BeginCombo("##textureGroups", selectedGroup)) {
                for (uint i = 0; i < groups.Length; i++) {
                    string group = groups[i];
                    if(UI::Selectable(group, group == selectedGroup)) {
                        selectedGroup = group;
                    }
                }
                UI::EndCombo();
        }
        UI::EndTable();
        
        UI::BeginTable("materials", 3, UI::TableFlags::SizingStretchSame);
        auto materialsList = TexturesLoading::list["materials"].GetKeys();
        uint count = 0;
        for(uint i = 0; i < materialsList.Length; i++) {
            auto currentMaterial = TexturesLoading::list["materials"][materialsList[i]];
            Json::Value materialGroups = currentMaterial["groups"];
            bool isCorrectGroup = false;
            for(uint j = 0; j < materialGroups.Length; j++) {
                const string currentGroup = materialGroups[j];
                isCorrectGroup = isCorrectGroup || (currentGroup == selectedGroup);
            }
            if(isCorrectGroup) {
                if(count != 0 && count % 3 == 0) {
                    UI::TableNextRow();
                }
                count++;
                UI::TableNextColumn();

                UI::BeginTable("materialTable##"+materialsList[i], 1, UI::TableFlags::SizingStretchSame);
                UI::TableNextRow();
                UI::TableNextColumn();
                string helper = currentMaterial["helper"];
                UI::BeginTable("titleMaterial##"+materialsList[i], 2, UI::TableFlags::SizingFixedFit);
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(currentMaterial["name"]);
                if(helper != "") {
                    UI::TableNextColumn();
                    UI::Text(Icons::QuestionCircle);
                    if(UI::IsItemHovered()) {   
                        UI::BeginTooltip();
                        UI::Text(helper);
                        UI::EndTooltip();
                    }
                }
                UI::EndTable();
                auto presetsKeyAvailable = currentMaterial["presets-order"];
                auto presetsAvailable = currentMaterial["presets"];
                UI::TableNextRow();
                UI::TableNextColumn();
                string currentPreset = presets[materialsList[i]];
                if (UI::BeginCombo("##texturePreset"+materialsList[i], presetsAvailable[currentPreset]["name"])) {
                    for (uint j = 0; j < presetsKeyAvailable.Length; j++) {
                        string preset = presetsKeyAvailable[j];
                        if(UI::Selectable(presetsAvailable[preset]["name"], preset == presets[materialsList[i]])) {
                            presets[materialsList[i]] = preset;
                        }
                    }
                    UI::EndCombo();
                }
                UI::TableNextRow();
                UI::TableNextColumn();
                
                bool canApply = CanApplyPreset(presetsAvailable[currentPreset]);
                if(DynamicButton("Apply##"+materialsList[i], vec2(), !canApply)) {
                    enablePlugin = true;
                    TexturesLoading::oldSettings = Json::Parse(selectedModWorks);
                    auto currentModWorks = Json::Parse(selectedModWorks);
                    currentModWorks[materialsList[i]] = presets[materialsList[i]];
                    selectedModWorks = Json::Write(currentModWorks);
                    TexturesLoading::updateOne = materialsList[i];
                }
                if(!canApply) {
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::TextWrapped(Icons::ExclamationTriangle + " This preset is only available if you use the ModWork method.");
                }
                UI::TableNextRow();
                UI::TableNextColumn();
                if(thumbs.Exists(materialsList[i])) {
                    CachedImage@ cachedImage = null;
                    thumbs.Get(materialsList[i], @cachedImage);
                    if(cachedImage.m_texture !is null) {
                        UI::Image(cachedImage.m_texture, vec2(200,200));
                    }
                }
                UI::EndTable();
            }
        }
        UI::EndTable();
      }
      
    }
}