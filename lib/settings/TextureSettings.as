namespace TextureSettings {
    string selectedQuality = "";
    Json::Value presets = Json::Array();
    dictionary thumbs = {};
    [SettingsTab name="Textures" icon="ListAlt"]
    void RenderSettings()
    {
      if(selectedQuality == "")
      {
        selectedQuality = textureQuality;
      }
      if(presets.Length == 0) {
        presets = Json::Parse(selectedModWorks);
      }
      if(ModWorkLoading::list.Length > 0) {
        ModWorkLoading::reloadModWorkPictures = true;
        if(UI::Button("Apply all##textures")) {
            enablePlugin = true;
            textureQuality = selectedQuality;
            ModWorkLoading::oldSettings = Json::Parse(selectedModWorks);
            selectedModWorks = Json::Write(presets);
            ModWorkLoading::updateAll = true;
        }
        UI::BeginTable("textureQuality", 3, UI::TableFlags::SizingFixedSame);
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("Texture Quality");
        UI::TableNextColumn();
        const auto qualities = ModWorkLoading::list["qualities"];
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
        if(UI::Button("Apply##textureQuality")) {
            enablePlugin = true;
            textureQuality = selectedQuality;
            ModWorkLoading::oldSettings = Json::Parse(selectedModWorks);
            ModWorkLoading::updateAll = true;
        }
        UI::EndTable();
        
        UI::BeginTable("materials", ModWorkLoading::list["materials"].Length, UI::TableFlags::SizingStretchSame);
        auto materialsList = ModWorkLoading::list["materials"].GetKeys();
        for(uint i = 0; i < materialsList.Length; i++) {
            UI::TableNextColumn();

            UI::BeginTable("materialTable##"+materialsList[i], 1, UI::TableFlags::SizingStretchSame);
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text(materialsList[i]);
            auto presetsAvailable = ModWorkLoading::list["materials"][materialsList[i]]["presets"].GetKeys();
            presetsAvailable.SortAsc();
            UI::TableNextRow();
            UI::TableNextColumn();
            if (UI::BeginCombo("##texturePreset"+materialsList[i], presets[materialsList[i]])) {
                for (uint j = 0; j < presetsAvailable.Length; j++) {
                    string preset = presetsAvailable[j];
                    if(UI::Selectable(preset, preset == presets[materialsList[i]])) {
                        presets[materialsList[i]] = preset;
                    }
                }
                UI::EndCombo();
            }
            UI::TableNextRow();
            UI::TableNextColumn();
            
            if(UI::Button("Apply##"+materialsList[i])) {
                enablePlugin = true;
                ModWorkLoading::oldSettings = Json::Parse(selectedModWorks);
                auto currentModWorks = Json::Parse(selectedModWorks);
                currentModWorks[materialsList[i]] = presets[materialsList[i]];
                selectedModWorks = Json::Write(currentModWorks);
                ModWorkLoading::updateOne = materialsList[i];
            }
            UI::TableNextRow();
            UI::TableNextColumn();
            if(thumbs.Exists(materialsList[i])) {
                CachedImage@ cachedImage = null;
                thumbs.Get(materialsList[i], @cachedImage);
                if(cachedImage.m_texture !is null) {
                    UI::Image(cachedImage.m_texture);
                }
            }
            UI::EndTable();
        }
        UI::EndTable();
      }
      
    }
}