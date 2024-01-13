namespace MapPreferences {
    string GetMapPreference(const string &in mapUid) {
        Json::Value preferences = GetPreferences();
        if(Json::Write(preferences[mapUid]) != "null") {
            const string a = preferences[mapUid];
            return a;
        } else {
            return defaultActionWhenMod;
        }
    }
    void SetMapPreference(const string &in mapUid, const string &in preference) {
        Json::Value preferences = GetPreferences();
        preferences[mapUid] = preference;
        mapPreferences = Json::Write(preferences);
    }

    Json::Value GetPreferences() {
        return Json::Parse(mapPreferences);
    }
}