bool isActive = IO::FolderExists(MODWORK_FOLDER);
string currentMap = "";
int errorCount = 0; // Keep track of error count. Disable plugin in case of error loop.
void Main() {
	auto app = cast<CTrackMania>(GetApp());
	InitPlugin();
	while(true) {
		if(enablePlugin) {
			try {
				CheckCurrentMap();
				if(MapLoading::reloadMap) {
					MapLoading::ReloadMap();
				}
				if(ModWorkLoading::updateAll) {
					ModWorkLoading::UpdateAll();
				}
				if(ModWorkLoading::updateOne != "") {
					ModWorkLoading::UpdateOne();
				}
				if(ModWorkLoading::reloadModWorkPictures) {
					ModWorkLoading::ReloadModWorkPictures();
				}
			} catch {
				errorCount++;
				string errorMessage = getExceptionInfo();
				error(errorMessage);
				UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Error", errorMessage, UI::HSV(1.0, 1.0, 1.0), 8000);
				if(errorCount > 50) {
					UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Error", "Too many errors. Exiting...", UI::HSV(1.0, 1.0, 1.0), 8000);
					return;
				}
			}
		}
		yield();
	}
}

void Render() {
	// Plugin can display 3 views in total
	if(PlayerPrompt::displayPlayerPrompt || RestartPrompt::displayRestartPrompt || ModWorkLoading::displayModWorkLoading) {
		UI::Begin("Better Texture Mod", UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse);
		// This view asks if the player want to enable/disable plugin on a map with an already custom mod
		if(PlayerPrompt::displayPlayerPrompt) {
			PlayerPrompt::Render();
		}
		// When player updates settings, the plugin will ask if the players want to reload the map/rejoin server
		if(RestartPrompt::displayRestartPrompt) {
			RestartPrompt::Render();
		}
		// When textures are downloading, a loading indicator will be displayed
		if(ModWorkLoading::displayModWorkLoading) {
			ModWorkLoading::Render();
		}
		UI::End();
	}

	// Render the settings in a different window
	if(togglePlugin) {
		UI::SetNextWindowSize(600, 600);
		if(UI::Begin("Better Texture Mod - Settings", togglePlugin, UI::WindowFlags::NoCollapse)) {	
			UI::BeginTabBar("betterTextureModSettings");
			if(UI::BeginTabItem(Icons::PaintBrush + " Textures##betterTextureMod")) {
				TextureSettings::RenderSettings();
				UI::EndTabItem();
			}
			if(UI::BeginTabItem(Icons::ListAlt + " Advanced##betterTextureMod")) {
				AdvancedSettings::RenderSettings();
				UI::EndTabItem();
			}
			UI::EndTabBar();
			UI::End();
		}
	}
}

void RenderMenu()
{
	if (UI::MenuItem("\\$9cf" + Icons::PaintBrush + "\\$z Better Texture Mod", "", togglePlugin)) {
		togglePlugin = !togglePlugin;
	}
}