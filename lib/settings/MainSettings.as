namespace MainSettings {
    [SettingsTab name="Main" icon="Cogs"]
    void RenderSettings()
    {
        UI::BeginTable("enablePluginBTM", 2, UI::TableFlags::SizingFixedFit);
        UI::TableNextColumn();
        enablePlugin = UI::Checkbox("Enable plugin", enablePlugin);
        UI::TableNextColumn();
        UI::Text(Icons::QuestionCircle);
        if(UI::IsItemHovered()) {   
            UI::BeginTooltip();
            UI::Text("If disabled, the plugin will not alter the ModWork folder.");
            UI::EndTooltip();
        }
        UI::EndTable();
        
        UI::BeginTable("enableNotificationsBTM", 2, UI::TableFlags::SizingFixedFit);
        UI::TableNextColumn();
        enableNotifications = UI::Checkbox("Enable notifications", enableNotifications);
        UI::TableNextColumn();
        UI::Text(Icons::QuestionCircle);
        if(UI::IsItemHovered()) {   
            UI::BeginTooltip();
            UI::Text("If enabled, you will be notified on startup when new textures/presets are released.");
            UI::EndTooltip();
        }
        UI::EndTable();

        if(modMethod == "ModWork") {
            UI::BeginTable("enableDoubleLoadingBTM", 2, UI::TableFlags::SizingFixedFit);
            UI::TableNextColumn();
            enableDoubleLoading = UI::Checkbox("Enable double loading", enableDoubleLoading);
            UI::TableNextColumn();
            UI::Text(Icons::QuestionCircle);
            if(UI::IsItemHovered()) {   
                UI::BeginTooltip();
                UI::Text("Will automatically reload map when switching from a map with a mod to a map without a mod (and vice versa).\n"
                "Only works if you chose to disable plugin when map has a mod.\n"+
                ColoredString("$F93It is not recommended to use this setting if you are likely to join servers that are full within a second\n"
                "(e.g. Spammiej Of The Day)."));
                UI::EndTooltip();
            }
            UI::EndTable();

            
            UI::BeginTable("showReloadWarningBTM", 2, UI::TableFlags::SizingFixedFit);
            UI::TableNextColumn();
            showReloadWarning = UI::Checkbox("Show reload warning", showReloadWarning);
            UI::TableNextColumn();
            UI::Text(Icons::QuestionCircle);
            if(UI::IsItemHovered()) {   
                UI::BeginTooltip();
                UI::Text("If using ModWork, this warning will be displayed if you need to reload the map to enable/disable textures.");
                UI::EndTooltip();
            }
            UI::EndTable();
        }

    }
}