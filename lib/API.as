// Source : https://github.com/GreepTheSheep/openplanet-maniaexchange-menu/blob/main/src/Utils/API.as
namespace API
{
    bool apiInUse = false;
    Net::HttpRequest@ DeclareHttpRequest(const string &in url, uint64 since = 0)
    {
        Net::HttpRequest ret();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
        if (since > 0) {
            ret.Headers.Set("If-Modified-Since", Time::FormatStringUTC("%a, %d %b %Y %H:%M:%S GMT", since));
        }

        trace(tostring(ret.Method) + ": " + url);
        ret.Start();
        return ret;
    }
    Net::HttpRequest@ GetAsync(const string &in url, uint64 since = 0)
    {
        Net::HttpRequest@ req = DeclareHttpRequest(url, since);
        while (!req.Finished()) {
            apiInUse = true;
            yield();
        }
        apiInUse = false;
        return req;
    }

    string GetCachedAsync(const string &in url, bool useCacheOnly = false) {
        if (!url.StartsWith(BASE_URL)) {
            error("Requested a URL that is not relative to '" + BASE_URL + "'!");
            return "";
        }

        string cachePath = CACHE_FOLDER + "/" + url.SubStr(BASE_URL.Length);
        bool exists = IO::FileExists(cachePath);
        if(useCacheOnly) { // useCacheOnly is used when applying textures on boot. We don't want to fetch any data without user prompt.
            if(exists) {
                return cachePath;
            } else {
                return "";
            }
        }
        uint64 modifiedSince = exists ? IO::FileModifiedTime(cachePath) : 0;

        Net::HttpRequest@ req = GetAsync(url, modifiedSince);
        if (req.ResponseCode() == 304) {
            trace("cached: " + url);
        } else {
            if (exists) {
                IO::Delete(cachePath);
            } else {
                string parentDir = Regex::Match(cachePath, "^(.*?)[^/]+$")[1];
                IO::CreateFolder(parentDir, true);
            }
            req.SaveToFile(cachePath);
        }

        return cachePath;
    }

    Json::Value GetAsyncJson(const string &in url) {
        return GetAsync(url).Json();
    }
}