bool isActive = IO::FolderExists(MODWORK_FOLDER);
string currentMap = "";
int errorCount = 0; // Keep track of error count. Disable plugin in case of error loop.
void Main() {
	auto app = cast<CTrackMania>(GetApp());

	/*
		Safety measure in case of breaking update
	 */
	if(disablePluginNextBoot) {
		enablePlugin = false; // We disable plugin as a safety measure if game crashed while applying textures
		disablePluginNextBoot = false;
		UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Game crashed :(", 
		"Your game crashed while applying textures. It is most likely due to the plugin and it has been disabled as a safety measure. You can enable it again in Settings => Better Texture Mod and reload plugin. "
		"If the Modless method always makes your game crash, you can report it and switch to ModWork for now.", 
		UI::HSV(1.0, 1.0, 1.0), 8000);
	}
	InitPlugin();
	awaitable@ updateAllThread = null;
	awaitable@ updateOneThread = null;
	awaitable@ reloadModWorkPicturesThread = null;
	while(true) {
		if(enablePlugin) {
			try {
				ModWorkManager::CheckCurrentMap();
				if(MapLoading::reloadMap) {
					MapLoading::ReloadMap();
				}
				if(TexturesLoading::updateAll && (updateAllThread is null || !updateAllThread.IsRunning())) {
					@updateAllThread = startnew(UpdateAllTextures);
				}
				if(TexturesLoading::updateOne != "" && (updateOneThread is null || !updateOneThread.IsRunning())) {
					@updateOneThread = startnew(TexturesLoading::UpdateOne);
				}
				if(TexturesLoading::reloadModWorkPictures && (reloadModWorkPicturesThread is null || !reloadModWorkPicturesThread.IsRunning())) {
					@reloadModWorkPicturesThread = startnew(TexturesLoading::ReloadModWorkPictures);
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
		if(PlayerPrompt::displayPlayerPrompt || RestartPrompt::displayRestartPrompt || TexturesLoading::displayTexturesLoading) {
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
			if(TexturesLoading::displayTexturesLoading) {
				TexturesLoading::Render();
			}
			UI::End();
		}

		// Render the settings in a different window
		if(togglePlugin) {
			UI::SetNextWindowSize(600, 600);
			if(UI::Begin("Better Texture Mod - Settings", togglePlugin, UI::WindowFlags::NoCollapse)) {	
				if(!ModlessManager::hasLoadedFids && modMethod == "Modless") {
					UI::TextWrapped(Text::OpenplanetFormatCodes("$F93The plugin has not been able to load ressources. You need to restart the whole game or switch to ModWork."));
				}
				UI::BeginTabBar("betterTextureModSettings");
				if(UI::BeginTabItem(Icons::Cogs + " Main##betterTextureMod")) {
					MainSettings::RenderSettings();
					UI::EndTabItem();
				}
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


void OnDestroyed() { 
	if(modMethod == "Modless") {
		ModlessManager::RestoreDefaultTextures();
	} else {
		if(ModWorkManager::IsModWorkBTMOnly()) {
			ModWorkManager::DisableModWork(); // If plugin is disabled/uninstalled, we disable ModWork to prevent people being stuck with custom textures
		} else {
			// If the ModWork folder contains anything else than plugin textures (such as skids), we don't disable
			UI::ShowNotification("Better Texture Mod - Disabling textures", "ModWork folder contains other files than plugin textures. To prevent any loss, it has been kept.");
		}
	}
}
void OnDisabled() {
	OnDestroyed();
 }