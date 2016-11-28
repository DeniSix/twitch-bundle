using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;
using System.Text.RegularExpressions;

namespace GitHubReleases
{
    public class Resolver
    {
        private const string USER_AGENT = "GitHubReleases v0";
        private const string LATEST_RELEASE_URL = "https://api.github.com/repos/{0}/releases/latest";

        /// <summary>
        /// Returns size of file or -1
        /// </summary>
        [DllExport("GetLatestReleaseLink", CallingConvention = CallingConvention.StdCall)]
        public static int GetLatestReleaseLink(
            [MarshalAs(UnmanagedType.BStr)] string repo,
            [MarshalAs(UnmanagedType.BStr)] string pattern,
            [MarshalAs(UnmanagedType.BStr)] out string result)
        {
            string apiUrl = string.Format(LATEST_RELEASE_URL, repo);
            HttpWebRequest http = (HttpWebRequest)WebRequest.Create(apiUrl);
            http.UserAgent = USER_AGENT;
            var stream = http.GetResponse().GetResponseStream();
            var sr = new StreamReader(stream);
            var content = sr.ReadToEnd();

            Regex regex = new Regex(pattern);
            
            var json = JSONSerializer<ReleaseInfo>.DeSerialize(content);
            foreach (var asset in json.assets)
            {
                var link = asset.browser_download_url;
                Match match = regex.Match(link);
                if (match.Success)
                {
                    result = link;
                    return asset.size;
                }
            }

            result = "";
            return -1;
        }
    }

    [DataContract]
    public class AssetInfo
    {
        [DataMember]
        public string browser_download_url { get; set; }

        [DataMember]
        public int size { get; set; }
    }

    [DataContract]
    public class ReleaseInfo
    {
        [DataMember]
        public AssetInfo[] assets { get; set; }
    }

    public static class JSONSerializer<TType> where TType : class
    {
        /// <summary>
        /// Serializes an object to JSON
        /// </summary>
        public static string Serialize(TType instance)
        {
            var serializer = new DataContractJsonSerializer(typeof(TType));
            using (var stream = new MemoryStream())
            {
                serializer.WriteObject(stream, instance);
                return Encoding.Default.GetString(stream.ToArray());
            }
        }

        /// <summary>
        /// DeSerializes an object from JSON
        /// </summary>
        public static TType DeSerialize(string json)
        {
            using (var stream = new MemoryStream(Encoding.Default.GetBytes(json)))
            {
                var serializer = new DataContractJsonSerializer(typeof(TType));
                return serializer.ReadObject(stream) as TType;
            }
        }
    }
}
