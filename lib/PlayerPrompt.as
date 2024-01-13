namespace PlayerPrompt {
    bool displayPlayerPrompt = false;
    void Render() {
      if(isActive) {
        UI::TextWrapped("This map uses a custom mod. It is currently disabled, do you want to enable it ?\nKeep in mind it will also disable every custom ModWork (such as Custom Skids).");
      } else {
        UI::TextWrapped("This map uses a custom mod. It is currently enabled, do you want to keep it enabled ?\nKeep in mind it will also disable every custom ModWork (such as Custom Skids)."); 
      }
      UI::BeginTable("playerPrompt", 4, UI::TableFlags::SizingFixedFit);
      UI::TableNextRow();
      UI::TableNextColumn();
      if(UI::Button("Yes, always")) {
        if(isActive) {
            RestartPrompt::displayRestartPrompt = true;
        }
        defaultActionWhenMod = "disable_modwork";
        displayPlayerPrompt = false;
      }
        UI::TableNextColumn();
        if(UI::Button("Yes, for this map")) {
            if(isActive) {
                RestartPrompt::displayRestartPrompt = true;
            }
            MapPreferences::SetMapPreference(currentMap, "disable_modwork");
            displayPlayerPrompt = false;
        }
        UI::TableNextColumn();
        if(UI::Button("No, for this map")) {
            if(!isActive) {
                RestartPrompt::displayRestartPrompt = true;
            }
            MapPreferences::SetMapPreference(currentMap, "apply_modwork");
            displayPlayerPrompt = false;
        }
      UI::TableNextColumn();
      if(UI::Button("No, never")) {
        if(!isActive) {
            RestartPrompt::displayRestartPrompt = true;
        }
        defaultActionWhenMod = "apply_modwork";
        displayPlayerPrompt = false;
      }
      UI::EndTable();
      UI::TextWrapped('By selecting "Yes, always", the plugin will be disabled for every map with a custom mod. The plugin will automatically enable itself on maps without mods. Keep it mind it disables custom ModWork. Plugins such as "Custom Skidmarks" will be affected. You can change this choice in plugin settings.');
    }
}