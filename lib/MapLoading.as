namespace MapLoading {
    bool reloadMap = false;
    void ReloadMap() {
        reloadMap = false;
        auto app = cast<CTrackMania>(GetApp());
        if(IsServer()) {
            app.ManiaPlanetScriptAPI.OpenLink(GetJoinLink(), CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
        } else {
            string map = app.RootMap.MapInfo.Fid.FullFileName;
            map = map.Replace("/", "\\");
            app.BackToMainMenu();
            while(!app.ManiaTitleControlScriptAPI.IsReady) {
                yield();
            }
			if(Permissions::PlayLocalMap()) {
				app.ManiaTitleControlScriptAPI.PlayMap(map, "", ""); // might not work with campaign maps
			}
        }
    }
}