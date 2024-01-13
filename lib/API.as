// Source : https://github.com/GreepTheSheep/openplanet-maniaexchange-menu/blob/main/src/Utils/API.as
namespace API
{
    bool apiInUse = false;
    Net::HttpRequest@ DeclareHttpRequest(const string &in url)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
        trace(tostring(ret.Method) + ": " + url);
        ret.Start();
        return ret;
    }
    Net::HttpRequest@ GetAsync(const string &in url)
    {
        auto req = DeclareHttpRequest(url);
        while (!req.Finished()) {
            apiInUse = true;
            yield();
        }
        apiInUse = false;
        return req;
    }

    Json::Value GetAsyncJson(const string &in url) {
        return GetAsync(url).Json();
    }
}