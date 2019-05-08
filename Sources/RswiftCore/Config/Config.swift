//
//  Config.swift
//  RswiftCore
//
//  Created by Sergey Plotkin on 5/8/19.
//

import Foundation
import Yams

struct Config: Codable {
    let inputs: [String]
    let baseLocale: String
    let enabledGenerators: [Generator]
    
    private init(inputs: [String], baseLocale: String = "Base", enabledGenerators: [Generator] = Generator.allCases) {
        self.inputs = inputs
        self.baseLocale = baseLocale
        self.enabledGenerators = enabledGenerators
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inputs = try container.decode([String].self, forKey: .inputs)
        baseLocale = try container.decodeIfPresent(String.self, forKey: .baseLocale) ?? "Base"
        enabledGenerators = try container.decodeIfPresent([Generator].self, forKey: .enabledGenerators) ?? Generator.allCases
    }
}

extension Config {
    static func load(fromFile path: URL) throws -> Config {
        let decoder = YAMLDecoder()
        let config = try String(contentsOf: path)
        return try decoder.decode(Config.self, from: config, userInfo: [:])
    }
    
    static func defaultConfig() -> Config {
        return Config(inputs: [])
    }
    
    func inputFilePaths(basePath: URL) -> [String] {
        if inputs.isEmpty {
            return []
        }
        
        return inputs
            .compactMap { !$0.isEmpty ? $0 : nil }
            .map { URL(fileURLWithPath: $0, relativeTo: basePath).path }
            .flatMap { Glob(pattern: $0).paths }
            .filter { !URL(fileURLWithPath: $0).pathExtension.isEmpty }
    }
}

enum Generator: String, Codable, CaseIterable {
    case image
    case strings
    case color
    case nib
    case font
    case storyboard
    case segue
    case resourceFile
    case reuseIdentifier
    
    func createWithResources(_ resources: Resources) -> StructGenerator {
        switch self {
        case .color:
            return ColorStructGenerator(assetFolders: resources.assetFolders)
        case .font:
            return FontStructGenerator(fonts: resources.fonts)
        case .image:
            return ImageStructGenerator(assetFolders: resources.assetFolders, images: resources.images)
        case .nib:
            return NibStructGenerator(nibs: resources.nibs)
        case .resourceFile:
            return ResourceFileStructGenerator(resourceFiles: resources.resourceFiles)
        case .reuseIdentifier:
            return ReuseIdentifierStructGenerator(reusables: resources.reusables)
        case .segue:
            return SegueStructGenerator(storyboards: resources.storyboards)
        case .storyboard:
            return StoryboardStructGenerator(storyboards: resources.storyboards)
        case .strings:
            return StringsStructGenerator(localizableStrings: resources.localizableStrings)
        }
    }
}
