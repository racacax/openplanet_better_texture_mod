namespace ModlessManager {
// Credits to XertroV and his Modless Skids plugin for most of the code

    bool hasLoadedFids = false;
    bool isReloadingMap = false;
    dictionary defaultTextures;
    const string GAME_FID_PATH = "GameData/Stadium/Media/Texture/Image/";


    /*
        Allow to load a fid corresponding to the texture file requested (ex : RoadIce_D.dds)
    */
    CSystemFidFile@ GetGameFid(const string &in file) {
        const string finalPath = GAME_FID_PATH + file;
        auto textureGameFid = Fids::GetGame(finalPath);

        if (textureGameFid.Nod is null) {
            Fids::Preload(textureGameFid);
            if (textureGameFid.Nod !is null) {
                textureGameFid.Nod.MwAddRef();
                
                if (!defaultTextures.Exists(finalPath)) {
                    @defaultTextures[finalPath] = cast<CPlugFileDds>(textureGameFid.Nod);
                }
            }
        }
        return textureGameFid;
    }

    /*
        Set the corresponding cached to the corresponding in-game fid ("GameData/Stadium/Media/Texture/Image/" + file)
    */
    void SetTexture(const string &in cachedFile, const string &in file) {
        bool fidsLoaded = true;
        const string userPath = "Skins/Stadium/BetterTextureMod";    

        string mainPath = IO::FromUserGameFolder(userPath).Replace("\\", "/");
        IO::CreateFolder(mainPath);
        CopyFile(cachedFile, mainPath + "/" + file);

        auto textureFolder = Fids::GetUserFolder(userPath);
        if (textureFolder is null) warn("ApplyTexture: failed to get user folder for texture!");
        else Fids::UpdateTree(textureFolder);
        auto gbTexture = Fids::GetUser(userPath + "/" + file);
        if (gbTexture is null || gbTexture.ByteSize == 0) {
            trace("Could not load texture .dds file from: " + file);
            return;
        }

        if (gbTexture.Nod is null) {
            Fids::Preload(gbTexture);
            if (gbTexture.Nod !is null) {
                gbTexture.Nod.MwAddRef();
            } else {
                fidsLoaded = false;
            }
        }
        auto textureGameFid = GetGameFid(file);
        if(textureGameFid.Nod is null) {
            fidsLoaded = false;
        }
        
        if(fidsLoaded) {
            SetFidNod(textureGameFid, gbTexture.Nod);
            warn("DEBUG set " + file);
        } else {
            error("Couldn't load "+ file + " fids correctly.");
        }
    }

    /*
        Get the memory offset of the fid based on its path
    */
    uint16 GetOffset(CMwNod@ obj, const string &in memberName) {
        if (obj is null) return 0xFFFF;
        // throw exception when something goes wrong.
        auto ty = Reflection::TypeOf(obj);
        if (ty is null) throw("could not find a type for object");
        auto memberTy = ty.GetMember(memberName);
        if (memberTy is null) throw(ty.Name + " does not have a child called " + memberName);
        if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
        return memberTy.Offset;
    }

    /*
        Replace the previous nod (texture) of the in-game fid corresponding to our texture, by our new one.
    */
    void SetFidNod(CSystemFidFile@ fid, CMwNod@ nod) {
        Dev::SetOffset(fid, GetOffset(fid, "Nod"), nod);
    }
    // Preloading fids on startup is mandatory to be able to update textures
    void PreloadFids(Json::Value files) {
        for(uint i = 0; i< files.Length; i++) {
            warn("DEBUG preloading " + string(files[i]));
            GetGameFid(files[i]);
        }
    }

    /*
        To refresh textures with the Modless method, we reload the map by creating the ModWork folder.
        We do an aditionnal reload if current map has a mod. We don't need to if there isn't one.
    */
    void ReloadMap() {
        if(isReloadingMap) {
            // If user applied multiple textures before reloading, we don't want to have multiple Reload threads
            return;
        }
        isReloadingMap = true;
        bool folderExists = IO::FolderExists(MODWORK_FOLDER);
        if(!folderExists) {    
            IO::CreateFolder(MODWORK_FOLDER); // Creating a ModWork folder allow textures to refresh. Weird flex but OK
            hasTriggeredModWorkFolderCreation = true;
        }
        while(!IsInAMap()) { yield(); }
        sleep(4000); // to be sure the textures were indeed loaded
        auto app = cast<CTrackMania>(GetApp());
        if(ModWorkManager::IsModWorkBTMOnly() && hasTriggeredModWorkFolderCreation) { // If folder existed previously, it means there was custom modwork already and we don't need to load the map twice
            IO::DeleteFolder(MODWORK_FOLDER, true);
            if(app.RootMap.ModPackDesc !is null) { // we only need to reload twice if map has a mod
                MapLoading::ReloadMap();
            }
        }
        hasTriggeredModWorkFolderCreation = false;
        isReloadingMap = false;
    }

    void RestoreDefaultTextures() {
        if(!IsInAMap()) {
            array<string> texturesKeys = defaultTextures.GetKeys();
            for (uint i = 0; i < texturesKeys.Length; i++) {
                const string path = texturesKeys[i];
                auto fid = Fids::GetGame(path);
                SetFidNod(fid, cast<CMwNod>(defaultTextures[path]));
                warn("Restoring "+ path + "...");
            }
            UI::ShowNotification("Better Texture Mod - Restoring textures", 
            "If some textures are not restored properly, you might need to load an empty map or restart the game completly.");
        } else {
            UI::ShowNotification("Better Texture Mod - Cannot restore textures", 
            "You are currently in a map so it is not safe to restore textures back to default.");
        }
    }
}