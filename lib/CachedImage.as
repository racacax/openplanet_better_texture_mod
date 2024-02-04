// From : https://github.com/openplanet-nl/plugin-manager/blob/master/src/Utils/CachedImage.as
class CachedImage
{
	string m_url;
	UI::Texture@ m_texture;

	void DownloadFromURLAsync()
	{
		IO::File image(API::GetCachedAsync(m_url), IO::FileMode::Read);
		@m_texture = UI::LoadTexture(image.Read(image.Size()));
		if (m_texture.GetSize().x == 0) {
			@m_texture = null;
		}
	}
}

namespace Images
{
	dictionary g_cachedImages;

	CachedImage@ FindExisting(const string &in path)
	{
		CachedImage@ ret = null;
		g_cachedImages.Get(path, @ret);
		return ret;
	}

	CachedImage@ CachedFromURL(const string &in path)
	{
		// Return existing image if it already exists
		auto existing = FindExisting(path);
		if (existing !is null) {
			return existing;
		}

		// Create a new cached image object and remember it for future reference
		auto ret = CachedImage();
		ret.m_url = path;
		g_cachedImages.Set(path, @ret);

		// Begin downloading
		startnew(CoroutineFunc(ret.DownloadFromURLAsync));
		return ret;
	}
}