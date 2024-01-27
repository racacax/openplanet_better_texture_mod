namespace MapLoading {
    bool reloadMap = false;
    // Based on https://github.com/XertroV/tm-better-totd/blob/d2dcc367968535e1ae0fc3b990712437132e6027/src/API/Core.as#L26
    string GetMapUrl(const string &in mapUid) {
        CTrackMania@ app = cast<CTrackMania@>(GetApp());
        CTrackManiaMenus@ manager = cast<CTrackManiaMenus@>(app.MenuManager);
        if(manager is null) {
            return "";
        }
        CGameManiaAppTitle@ title = manager.MenuCustom_CurrentManiaApp;
        if(title is null) {
            return "";
        }
        CGameUserManagerScript@ userMgr = title.UserMgr;
        if(userMgr is null || userMgr.Users.Length == 0) {
            return "";
        }
        CGameUserScript@ currentUser = userMgr.Users[0];
        if(currentUser is null) {
            return "";
        }
        CGameDataFileManagerScript@ fileMgr = title.DataFileMgr;
        if(fileMgr is null) {
            return "";
        }
        CWebServicesTaskResult_NadeoServicesMapScript@ task = fileMgr.Map_NadeoServices_GetFromUid(currentUser.Id, mapUid);
        while(task.IsProcessing) {
            yield();
        }
        if(task.HasSucceeded) {
            const string mapUrl = task.Map.FileUrl;
            fileMgr.TaskResult_Release(task.Id);
			return mapUrl;
        }
        return "";
    }

    void ReloadMap() {
        reloadMap = false;
        auto app = cast<CTrackMania>(GetApp());
        if(IsServer()) {
            const string joinLink = GetJoinLink();
            // when server has a password, joining directly may cause a wrong password prompt. Going back to main menu and waiting prevents that.
            app.BackToMainMenu();
            while(!app.ManiaTitleControlScriptAPI.IsReady) {
                yield();
            }
            app.ManiaPlanetScriptAPI.OpenLink(joinLink, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
        } else {
            string map = app.RootMap.MapInfo.Fid.FullFileName;
            const string mapUid = app.RootMap.MapInfo.MapUid;
            map = map.Replace("/", "\\");
            app.BackToMainMenu();
            while(!app.ManiaTitleControlScriptAPI.IsReady) {
                yield();
            }
			if(Permissions::PlayLocalMap()) {
				app.ManiaTitleControlScriptAPI.PlayMap(map, "", ""); // works if stored in the Trackmania user folder
                if(app.ManiaTitleControlScriptAPI.IsReady) {
                    const string mapUrl = GetMapUrl(mapUid); // Mandatory for maps stored in Cache
                    if(mapUrl != "") {
				        app.ManiaTitleControlScriptAPI.PlayMap(mapUrl, "", "");
                    }
                    if(app.ManiaTitleControlScriptAPI.IsReady) {
                        UI::ShowNotification(Icons::Kenney::TimesCircle + " Better Texture Mod - Error", "Couldn't reload map, you have to reload it yourself.", UI::HSV(1.0, 1.0, 1.0), 8000);
                    }
                }
			}
        }
    }
}