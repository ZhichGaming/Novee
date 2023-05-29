//
//  Gogoanime.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation
import SwiftSoup
import CommonCrypto

class Gogoanime: AnimeFetcher, AnimeSource {
    override init(label: String = "Gogoanime", sourceId: String = "gogoanime", baseUrl: String = "https://www1.gogoanime.bid") {
        super.init(label: label, sourceId: sourceId, baseUrl: baseUrl)
    }
    
    func getMedia(pageNumber: Int) async -> [Anime] {
        do {
            guard let requestUrl = URL(string: baseUrl + "?page=\(pageNumber)") else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            guard let stringData = String(data: data, encoding: .utf8), !stringData.isEmpty else {
                Log.shared.msg("An error occured while fetching anime.")
                return []
            }
            
            let document = try SwiftSoup.parse(stringData)
            
            guard let animes = try document.getElementsByClass("last_episodes").first()?.child(0).children() else {
                Log.shared.msg("An error occured while fetching anime.")
                return []
            }
            
            var result: [Anime] = []
                        
            for anime in animes {
                let converted = Anime(
                    title: try anime.child(1).child(0).text(),
                    detailsUrl: try URL(string: getDetailsUrlFromLatestChapter(url: anime.child(0).child(0).attr("href"))),
                    imageUrl: try URL(string: anime.child(0).child(0).child(0).attr("src")),
                    segments: [Episode(title: try anime.child(2).text(), segmentUrl: URL(string: try anime.child(0).child(0).attr("href"))!)])
                
                result.append(converted)
            }
            
            DispatchQueue.main.sync {
                AnimeVM.shared.objectWillChange.send()
            }
            
            super.mediaData = result
            return result
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func getSearchMedia(pageNumber: Int, searchQuery: String) async -> [Anime] {
        do {
            let safeSearchQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

            guard let requestUrl = URL(string: baseUrl + "/search.html?keyword=\(safeSearchQuery)&page=\(pageNumber)") else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            guard let stringData = String(data: data, encoding: .utf8), !stringData.isEmpty else {
                Log.shared.msg("An error occured while fetching anime.")
                return []
            }
            
            let document = try SwiftSoup.parse(stringData)
            
            guard let animes = try document.getElementsByClass("items").first()?.children() else {
                Log.shared.msg("An error occured while fetching anime.")
                return []
            }
            
            var result: [Anime] = []
                        
            for anime in animes {
                let converted = Anime(
                    title: try anime.child(1).child(0).text(),
                    detailsUrl: try URL(string: getDetailsUrlFromLatestChapter(url: anime.child(0).child(0).attr("href").replacingOccurrences(of: "/category", with: ""))),
                    imageUrl: try URL(string: anime.child(0).child(0).child(0).attr("src")),
                    segments: [Episode(title: try anime.child(2).text(), segmentUrl: URL(string: try anime.child(0).child(0).attr("href"))!)])
                
                result.append(converted)
            }
            
            DispatchQueue.main.sync {
                AnimeVM.shared.objectWillChange.send()
            }
            
            super.mediaData = result
            return result
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func getMediaDetails(media: Anime) async -> Anime? {
        do {
            guard let requestUrl = media.detailsUrl else {
                Log.shared.msg("No valid details url.")
                return nil
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            guard let stringData = String(data: data, encoding: .utf8), !stringData.isEmpty else {
                Log.shared.msg("An error occured while fetching anime. Converting to string failed.")
                return nil
            }
            
            let document = try SwiftSoup.parse(stringData)
            
            guard let infoElement = try document.getElementsByClass("anime_info_body_bg").first() else {
                Log.shared.msg("An error occured while fetching anime. Scraping infoElement failed.")
                return nil
            }
            
            var newAnime = media
            
            newAnime.title = try infoElement.child(1).text()
            newAnime.imageUrl = try URL(string: infoElement.child(0).attr("src"))
            
            newAnime.description = try infoElement.children().first(where: {
                try $0.text().contains("Plot Summary: ")
            })?.text().replacingOccurrences(of: "Plot Summary: ", with: "")
            
            newAnime.altTitles = try infoElement.children().first(where: {
                try $0.text().contains("Other name: ")
            })?.text().replacingOccurrences(of: "Other name: ", with: "").components(separatedBy: "; ")
            
            newAnime.tags = try infoElement.children().first(where: {
                try $0.text().contains("Genre: ")
            })?.children().filter {
                try !$0.text().contains("Genre: ")
            }.map {
                MediaTag(name: try $0.text(), url: try URL(string: $0.attr("href")))
            }
            
            newAnime.segments = try await getEpisodes(document: document)
            
            return newAnime
        } catch {
            Log.shared.error(error)
            return nil
        }
    }
    
    private func getEpisodes(document: Document) async throws -> [Episode]? {
        guard let id = try document.getElementById("movie_id")?.attr("value") else {
            Log.shared.msg("An error occured while fetching anime.")
            return nil
        }
        
        guard let defaultEpisode = try document.getElementById("default_ep")?.attr("value") else {
            Log.shared.msg("An error occured while fetching anime.")
            return nil
        }
        
        guard let alias = try document.getElementById("alias_anime")?.attr("value") else {
            Log.shared.msg("An error occured while fetching anime.")
            return nil
        }
        
        guard let requestUrl = URL(string: "https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=10000&id=\(id)&default_ep=\(defaultEpisode)&alias=\(alias)") else {
            Log.shared.msg("Invalid segments url.")
            return nil
        }

        let (data, _) = try await URLSession.shared.data(from: requestUrl)
        
        guard let stringData = String(data: data, encoding: .utf8), !stringData.isEmpty else {
            Log.shared.msg("An error occured while fetching anime.")
            return nil
        }
        
        let newDocument = try SwiftSoup.parse(stringData)
        
        guard let episodes = try newDocument.getElementById("episode_related")?.children() else {
            Log.shared.msg("Cannot find episodes.")
            return nil
        }
        
        var result = [Episode]()
        
        for episode in episodes.reversed() {
            result.append(Episode(title: try episode.child(0).child(0).text(), segmentUrl: try URL(string: baseUrl + episode.child(0).attr("href").trimmingCharacters(in: .whitespacesAndNewlines))!))
        }
        
        return result
    }
    
    func getStreamingUrl(for episode: Episode, anime: Anime) async -> Episode? {
        do {
            let (data, _) = try await URLSession.shared.data(from: episode.segmentUrl)
            
            guard let stringData = String(data: data, encoding: .utf8), !stringData.isEmpty else {
                Log.shared.msg("An error occured while fetching streaming URLs.")
                return nil
            }
            
            let document = try SwiftSoup.parse(stringData)
            
            guard let videoUrl = URL(string: try document.select("#load_anime > div > div > iframe").attr("src")) else {
                Log.shared.msg("An error occured while fetching streaming URLs.")
                return nil
            }
            
            var result = episode
            
            result.streamingUrls = try await extractSources(from: videoUrl)
            
            return result
        } catch {
            Log.shared.error(error)
            return nil
        }
    }
    
    func getDetailsUrlFromLatestChapter(url: String) -> String {
        var newString = url
        
        if let lowerBound = newString.range(of: "episode", options: .backwards)?.lowerBound {
            newString.removeSubrange(lowerBound..<newString.endIndex)
            newString.removeLast()
        }
        
        return baseUrl + "/category" + newString
    }
    
    func extractSources(from url: URL) async throws -> [StreamingUrl]? {
        var request = URLRequest(url: url)
        request.setValue(baseUrl, forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
            
        guard let responseString = String(data: data, encoding: .utf8) else {
            Log.shared.msg("An error occured while fetching streaming URLs. (2)")
            return nil
        }
                        
        let keyData = "37911490979715163134003223491201"
        let secondKeyData = "54674138327930866480207815084989"
        let ivData = "3134003223491201"
        
        let keys = (key: keyData, secondKey: secondKeyData, iv: ivData)
        
        var encryptedParams = String(responseString.split(separator: "data-value=\"")[1].split(separator: "\"><")[0]).aesDecrypt(key: keys.key, iv: keys.iv)
        
        let encrypt = encryptedParams?.split(separator: "&")[0]
        
        guard let encrypt = encrypt else {
            Log.shared.msg("An error occured while fetching streaming URLs. Encrypt is nil.)")
            return nil
        }
        
        guard let newEncryptParams = String(data: Data(encrypt.utf8), encoding: .utf8)?.aesEncrypt(key: keys.key, iv: keys.iv) else {
            Log.shared.msg("An error occured while fetching streaming URLs. New encrypted parameters are nil.)")
            return nil
        }
        
        encryptedParams = encryptedParams?.replacingOccurrences(of: "\(encrypt)", with: newEncryptParams)

        guard let encryptedParams = encryptedParams else {
            Log.shared.msg("An error occured while fetching streaming URLs. Encrypted parameters are nil.)")
            return nil
        }
                
        guard let encryptedDataRequestUrl = URL(string: "https://playtaku.online/encrypt-ajax.php?id=\(encryptedParams)&alias=\(encrypt)") else {
            Log.shared.msg("An error occured while fetching streaming URLs. Encrypted data request URL is broken. (6)")
            print("https://playtaku.online/encrypt-ajax.php?" + encryptedParams)
            return nil
        }
                
        var encryptedDataRequest = URLRequest(url: encryptedDataRequestUrl)
        
        encryptedDataRequest.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        encryptedDataRequest.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
        
        let (encryptedData, _) = try await URLSession.shared.data(for: encryptedDataRequest)
        
        let parsedData = try JSONDecoder().decode(Gogoanime.GogoanimeSourceData.self, from: encryptedData)
        let decryptedData = parsedData.data.aesDecrypt(key: keys.secondKey, iv: keys.iv)
        
        guard let decryptedData = decryptedData?.data(using: .utf8) else {
            Log.shared.msg("An error occured while fetching streaming URLs. Decrypted data is nil.")
            return nil
        }
        
        let parsedDecryptedData = try JSONDecoder().decode(Gogoanime.Source.self, from: decryptedData)

        var sources = [StreamingUrl]()

        if parsedDecryptedData.source?[0].file?.contains(".m3u8") ?? false, let source = parsedDecryptedData.source?[0] {
            guard let fileUrl = URL(string: source.file ?? "") else {
                Log.shared.msg("An error occured while fetching streaming URLs. File URL is nil.")
                return nil
            }
            
            let (resResult, _) = try await URLSession.shared.data(from: fileUrl)
            
            guard let stringResResult = String(data: resResult, encoding: .utf8) else {
                Log.shared.msg("An error occured while fetching streaming URLs. Res result is nil.")
                return nil
            }
            
            let resolutions = stringResResult.components(separatedBy: .newlines).map {
                if $0.contains("EXT-X-STREAM-INF") {
                    return $0.components(separatedBy: "RESOLUTION=")[1].components(separatedBy: ",")[0]
                }
                
                return ""
            }.filter { !$0.isEmpty }
                                    
            for resolution in resolutions {
                let index = parsedDecryptedData.source?[0].file?.lastIndex(of: "/")
                
                guard let index = index else {
                    Log.shared.msg("An error occured while fetching streaming URLs. Index is nil.")
                    return nil
                }
                
                let quality = resolution.components(separatedBy: "x")[1]
                guard let stringResolutionUrl = parsedDecryptedData.source?[0].file?[..<index] else {
                    Log.shared.msg("An error occured while fetching streaming URLs. Initial resolution URL is nil.")
                    return nil
                }
                
                guard let indexOfResolution = stringResResult.components(separatedBy: .newlines).firstIndex(where: { $0.contains(resolution) && !$0.contains(".m3u8") }) else {
                    Log.shared.msg("An error occured while fetching streaming URLs. Index of resolution is nil.")
                    return nil
                }

                guard let resolutionUrl = URL(string: stringResolutionUrl + "/" + stringResResult.components(separatedBy: .newlines)[indexOfResolution + 1]) else {
                    Log.shared.msg("An error occured while fetching streaming URLs. Resolution URL is nil.")
                    print(stringResolutionUrl + "/" + stringResResult.components(separatedBy: .newlines)[indexOfResolution])
                    return nil
                }
                                
                sources.append(StreamingUrl(
                    url: resolutionUrl,
                    isM3U8: resolutionUrl.absoluteString.contains(".m3u8"),
                    quality: quality + "p")
                )
            }
        }
        
        return sources
    }
    
    struct GogoanimeSourceData: Codable, Hashable {
        var data: String
    }
    
    struct Source: Codable {
        var source: [SourceFile]?
        var sourceBk: [SourceFile]?
        
        enum CodingKeys: String, CodingKey {
            case source
            case sourceBk = "source_bk"
        }
    }

    struct SourceFile: Codable {
        let file: String?
        let label: String?
        let type: String?
    }
}
