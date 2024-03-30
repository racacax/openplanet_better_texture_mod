const string BASE_URL = "https://bettertexturemod.racacax.fr/";

const string MODWORK_FOLDER = IO::FromUserGameFolder("Skins\\Stadium\\ModWork");

const string MODWORK_DISABLED_FOLDER = IO::FromUserGameFolder("Skins\\Stadium\\ModWorkDisabled");

const string CACHE_FOLDER = IO::FromStorageFolder("Cache");

const Json::Value CHOICES = Json::Parse('{"disable_modwork": "Yes, always", "apply_modwork" : "No, never", "unset": "Ask me everytime"}');

const Json::Value CHOICES_KEYS = CHOICES.GetKeys();

const Json::Value CHOICES_FOR_MAP = Json::Parse('{"disable_modwork": "Yes", "apply_modwork" : "No", "unset": "Ask me"}');

const Json::Value CHOICES_FOR_MAP_KEYS = CHOICES_FOR_MAP.GetKeys();

array<string> MOD_METHODS = {"Modless", "Modwork"};