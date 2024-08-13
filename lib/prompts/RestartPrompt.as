namespace RestartPrompt {
    bool displayRestartPrompt = false;
    void Render() {
      UI::Text("The map might need to be reloaded to apply changes. Do you want to reload it ?");
      UI::BeginTable("restartPrompt", 2, UI::TableFlags::SizingFixedFit);
      UI::TableNextRow();
      UI::TableNextColumn();
      if(UI::Button("Yes")) {
        if(modMethod == "Modless") {
          startnew(ModlessManager::ReloadMap);
        } else {
          startnew(ModWorkManager::CheckCurrentMapAndReload);
        }
        displayRestartPrompt = false;
      }
      UI::TableNextColumn();
      if(UI::Button("No")) {
        displayRestartPrompt = false;
      }
      UI::EndTable();
    }
}