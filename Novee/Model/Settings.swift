//
//  Settings.swift
//  Novee
//
//  Created by Nick on 2022-10-21.
//

import Foundation
import SwiftUI

struct Settings: Codable {
    var mangaSettings = MangaSettings()
}

enum NoveeColorScheme: String, Codable, CaseIterable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"
}

struct MangaSettings: Codable {
    enum ImageFitOption: String, Codable, CaseIterable {
        case fit = "Fit"
        case fill = "Fill"
        case original = "Original"
    }
    
    enum NavigationType: String, Codable, CaseIterable {
        case scroll = "Scroll"
        case singlePage = "Single Page"
        case doublePage = "Double Page"
    }
    
    enum ReadingDirection: String, Codable, CaseIterable {
        case leftToRight = "Left to Right"
        case rightToLeft = "Right to Left"
    }
    
    /// Color scheme, being light, dark or system. 
    var colorScheme: NoveeColorScheme = .system
    
    /// The name of the theme of the manga reader window.
    var selectedThemeName = "Default"
    
    /// The theme of the manga reader window.
    var selectedTheme: Theme? {
        Theme.themes.first { $0.name == selectedThemeName }
    }
    
    /// Image fit option.
    var imageFitOption = ImageFitOption.original
    
    /// Image navigation type.
    var navigationType = NavigationType.scroll
    
    /// Direction of images loading if `navigationType` is `.doublePage`.
    var readingDirection = ReadingDirection.rightToLeft
}

struct Theme: Codable, Hashable {
    /// Theme name.
    var name: String
    
    /// The custom color of the window background when it's light mode.
    var lightBackgroundColor: Color
    
    /// The custom color of the window background when it's dark mode.
    var darkBackgroundColor: Color
    
    /// The color of the text when it's light mode. This is for novels only.
    var lightTextColor: Color
    
    /// The color of the text when it's dark mode. This is for novels only.
    var darkTextColor: Color
    
    /// The name of the body font. This is for novels only.
    var fontName: String
    
    /// The size of the body font. This is for novels only.
    var fontSize: Double = 16
    
    enum CodingKeys: CodingKey {
        case name
        case lightBackgroundColor
        case darkBackgroundColor
        case lightTextColor
        case darkTextColor
        case fontName
        case fontSize
    }
    
    var font: Font {
        guard let nsFont = NSFont(name: fontName, size: fontSize) else {
            Log.shared.log("Error: Invalid font.", isError: true)
            return Font.body
        }
        
        return Font(nsFont)
    }
    
    var backgroundColor: Color {
        let colorScheme = SettingsVM.shared.settings.mangaSettings.colorScheme
        
        switch colorScheme {
        case .light:
            return lightBackgroundColor
        case .dark:
            return darkBackgroundColor
        case .system:
            return NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? darkBackgroundColor : lightBackgroundColor
        }
    }
    
    var textColor: Color {
        let colorScheme = SettingsVM.shared.settings.mangaSettings.colorScheme
        
        switch colorScheme {
        case .light:
            return lightTextColor
        case .dark:
            return darkTextColor
        case .system:
            return NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? darkTextColor : lightTextColor
        }
    }
}

enum Language: String, Codable, CaseIterable, Hashable {
    case AB = "Abkhazian",
         AA = "Afar",
         AF = "Afrikaans",
         AK = "Akan",
         SQ = "Albanian",
         AM = "Amharic",
         AR = "Arabic",
         AN = "Aragonese",
         HY = "Armenian",
         AS = "Assamese",
         AV = "Avaric",
         AE = "Avestan",
         AY = "Aymara",
         AZ = "Azerbaijani",
         BM = "Bambara",
         BA = "Bashkir",
         EU = "Basque",
         BE = "Belarusian",
         BN = "Bengali",
         BH = "Bihari languages",
         BI = "Bislama",
         BS = "Bosnian",
         BR = "Breton",
         BG = "Bulgarian",
         MY = "Burmese",
         CA = "Catalan",
         KM = "Central Khmer",
         CH = "Chamorro",
         CE = "Chechen",
         NY = "Chichewa",
         ZH = "Simplified Chinese",
         ZHRO = "Romanized Chinese",
         ZHHK = "Traditional Chinese",
         CU = "Old Bulgarian",
         CV = "Chuvash",
         KW = "Cornish",
         CO = "Corsican",
         CR = "Cree",
         HR = "Croatian",
         CS = "Czech",
         DA = "Danish",
         DV = "Divehi",
         NL = "Dutch",
         DZ = "Dzongkha",
         EN = "English",
         EO = "Esperanto",
         ET = "Estonian",
         EE = "Ewe",
         FO = "Faroese",
         FJ = "Fijian",
         FI = "Finnish",
         FR = "French",
         FF = "Fulah",
         GD = "Gaelic",
         GL = "Galician",
         LG = "Ganda",
         KA = "Georgian",
         DE = "German",
         KI = "Gikuyu",
         EL = "Greek (Modern)",
         KL = "Greenlandic",
         GN = "Guarani",
         GU = "Gujarati",
         HT = "Haitian",
         HA = "Hausa",
         HE = "Hebrew",
         HZ = "Herero",
         HI = "Hindi",
         HO = "Hiri Motu",
         HU = "Hungarian",
         IS = "Icelandic",
         IO = "Ido",
         IG = "Igbo",
         ID = "Indonesian",
         IA = "Interlingua (International Auxiliary Language Association)",
         IE = "Interlingue",
         IU = "Inuktitut",
         IK = "Inupiaq",
         GA = "Irish",
         IT = "Italian",
         JA = "Japanese",
         JARO = "Romanized Japanese",
         JV = "Javanese",
         KN = "Kannada",
         KR = "Kanuri",
         KS = "Kashmiri",
         KK = "Kazakh",
         RW = "Kinyarwanda",
         KV = "Komi",
         KG = "Kongo",
         KO = "Korean",
         KORO = "Romanized Korean",
         KJ = "Kwanyama, Kuanyama",
         KU = "Kurdish",
         KY = "Kyrgyz",
         LO = "Lao",
         LA = "Latin",
         LV = "Latvian",
         LB = "Letzeburgesch, Luxembourgish",
         LI = "Limburgish, Limburgan, Limburger",
         LN = "Lingala",
         LT = "Lithuanian",
         LU = "Luba-Katanga",
         MK = "Macedonian",
         MG = "Malagasy",
         MS = "Malay",
         ML = "Malayalam",
         MT = "Maltese",
         GV = "Manx",
         MI = "Maori",
         MR = "Marathi",
         MH = "Marshallese",
         RO = "Moldovan, Moldavian, Romanian",
         MN = "Mongolian",
         NA = "Nauru",
         NV = "Navajo, Navaho",
         ND = "Northern Ndebele",
         NG = "Ndonga",
         NE = "Nepali",
         SE = "Northern Sami",
         NO = "Norwegian",
         NB = "Norwegian Bokmål",
         NN = "Norwegian Nynorsk",
         II = "Nuosu, Sichuan Yi",
         OC = "Occitan (post 1500)",
         OJ = "Ojibwa",
         OR = "Oriya",
         OM = "Oromo",
         OS = "Ossetian, Ossetic",
         PI = "Pali",
         PA = "Panjabi, Punjabi",
         PS = "Pashto, Pushto",
         FA = "Persian",
         PL = "Polish",
         PT = "Portuguese",
         PTBR = "Brazilian Portugese",
         QU = "Quechua",
         RM = "Romansh",
         RN = "Rundi",
         RU = "Russian",
         SM = "Samoan",
         SG = "Sango",
         SA = "Sanskrit",
         SC = "Sardinian",
         SR = "Serbian",
         SN = "Shona",
         SD = "Sindhi",
         SI = "Sinhala, Sinhalese",
         SK = "Slovak",
         SL = "Slovenian",
         SO = "Somali",
         ST = "Sotho, Southern",
         NR = "South Ndebele",
         ES = "Castilian Spanish",
         ESLA = "Latin American Spanish",
         SU = "Sundanese",
         SW = "Swahili",
         SS = "Swati",
         SV = "Swedish",
         TL = "Tagalog",
         TY = "Tahitian",
         TG = "Tajik",
         TA = "Tamil",
         TT = "Tatar",
         TE = "Telugu",
         TH = "Thai",
         BO = "Tibetan",
         TI = "Tigrinya",
         TO = "Tonga (Tonga Islands)",
         TS = "Tsonga",
         TN = "Tswana",
         TR = "Turkish",
         TK = "Turkmen",
         TW = "Twi",
         UG = "Uighur, Uyghur",
         UK = "Ukrainian",
         UR = "Urdu",
         UZ = "Uzbek",
         VE = "Venda",
         VI = "Vietnamese",
         VO = "Volap_k",
         WA = "Walloon",
         CY = "Welsh",
         FY = "Western Frisian",
         WO = "Wolof",
         XH = "Xhosa",
         YI = "Yiddish",
         YO = "Yoruba",
         ZA = "Zhuang, Chuang",
         ZU = "Zulu"
    
    static func getValue(_ value: String) -> String? {
        for language in Language.allCases {
            if "\(language)" == value.replacingOccurrences(of: "-", with: "") {
                return language.rawValue
            }
        }
        
        return nil
    }
}
